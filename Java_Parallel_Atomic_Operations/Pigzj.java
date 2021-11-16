//Akhil Vinta
//405288527
//akhil.vinta@gmail.com

import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ConcurrentHashMap;
import java.nio.file.*;
import java.lang.*;
import java.io.*;
import java.util.concurrent.atomic.AtomicIntegerArray;
import java.util.zip.*;
import java.io.IOException;
import java.io.PrintStream;


class constants {
	public final static int BLOCK_SIZE = 131072;
	public final static int DICT_SIZE = 32768;
	public final static int GZIP_MAGIC = 0x8b1f;
	public final static int TRAILER_SIZE = 8;
}

public class Pigzj {

	private static CRC32 crc = new CRC32();

	public static void main(String[] args) throws FileNotFoundException, InterruptedException, IOException{

		ConcurrentHashMap<Integer, byte[]> block_id_to_compressed_contents = new ConcurrentHashMap<Integer, byte[]>();
		ConcurrentHashMap<Integer, byte[]> block_id_to_contents = new ConcurrentHashMap<Integer, byte[]>();
		
		crc.reset();
		PrintStream output_write = new PrintStream(System.out, true);
		
		int number_of_processors = Runtime.getRuntime().availableProcessors();

		if(args.length != 0){
			if(args.length == 2){
				if (args[0].equals("-p")){
					int given_param = Integer.parseInt(args[1]);
					if(given_param < 0 || given_param > number_of_processors){
						System.err.println("Number of processers entered in input is not valid");
						return;
					}
					else{
						number_of_processors = given_param;
					}
				}
				else{
					System.err.println("First input must be \"-p\"");
					return;
				}
			}
			else{
				System.err.println("Parameters must follow format \"-p\" \"n\"");
				Runtime.getRuntime().exit(1);
			}
		}


		ConcurrentHashMap<Integer, Integer> block_size = new ConcurrentHashMap<Integer, Integer>();
		ExecutorService executor = Executors.newFixedThreadPool(number_of_processors);
		write_to_output to_stdout = new write_to_output(block_id_to_compressed_contents);
		to_stdout.block_id_to_size = block_size;
		Thread output_write_thread = new Thread(to_stdout);

		InputStream inStream = System.in;
		long totalBytesRead = 0;
		
		byte[] blockBuf = new byte[constants.BLOCK_SIZE];
		int nBytes = inStream.read(blockBuf);
		if (nBytes > 0) {
			output_write_thread.start();
		}else{
			executor.shutdown();
			write_to_output.writeHeader();
			write_to_output.writeCompressorFinished(output_write);
			byte[] trailerBuf = new byte[constants.TRAILER_SIZE];
			write_to_output.writeTrailer(0,trailerBuf,0);
			Runtime.getRuntime().exit(0);
		}
		totalBytesRead += nBytes;

		int id_of_current_block = 0;
		while (nBytes > 0) {
			crc.update(blockBuf, 0, nBytes);
			if(id_of_current_block == 0)
				executor.execute(new SingleThreadedGZipCompressor(block_id_to_contents, block_id_to_compressed_contents, blockBuf, block_size, id_of_current_block, nBytes, true));
			else
				executor.execute(new SingleThreadedGZipCompressor(block_id_to_contents, block_id_to_compressed_contents, blockBuf, block_size, id_of_current_block, nBytes, false));
			blockBuf = new byte[constants.BLOCK_SIZE];
			nBytes = inStream.read(blockBuf);
			if (nBytes > 0) 
				totalBytesRead += nBytes;
			id_of_current_block++;
		}

		executor.shutdown();

		to_stdout.set_CRCValue((int)crc.getValue());
		to_stdout.set_Total((int)totalBytesRead);
		to_stdout.count_total_number_of_blocks(id_of_current_block);
		
		
		output_write_thread.join();

	}
}



class SingleThreadedGZipCompressor implements Runnable {

	public static PrintStream output_write = new PrintStream(System.out, true);

	byte[] blockBuf = new byte[constants.BLOCK_SIZE];
	int nBytes;
	int cur_id;
	boolean is_first;

	ConcurrentHashMap<Integer, byte[]> block_id_to_compressed_contents;
	ConcurrentHashMap<Integer, byte[]> block_id_to_contents;
	
	public void run() {
		try {
			compress();
		} catch (InterruptedException | IOException e) {
			e.printStackTrace();
		}
	}
	
	

	public void compress() throws InterruptedException, FileNotFoundException, IOException {
		byte[] cmpBlockBuf = new byte[constants.BLOCK_SIZE * 2];
		byte[] dictBuf = new byte[constants.DICT_SIZE];
		
		
		Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
		compressor.reset();

		byte[] dummy = new byte[0];
		long totalBytesRead = 0;
		boolean is_first_block;
		boolean is_invalid_compressed_block;
		int previous_block = cur_id - 1;
		
		synchronized (block_id_to_contents){
			if(nBytes < constants.DICT_SIZE)
				block_id_to_contents.put(cur_id, dummy);
			else{
				System.arraycopy(blockBuf, nBytes - constants.DICT_SIZE, dictBuf, 0, constants.DICT_SIZE);
				block_id_to_contents.put(cur_id, dictBuf);
			}
			block_id_to_contents.notifyAll();
		}

		if(cur_id == 0){
			is_first_block = true;
		}
		else{
			synchronized (block_id_to_contents){
				while(block_id_to_contents.containsKey(previous_block) == false){
					block_id_to_contents.wait();
				} 
				int size_of_previous_block = block_id_to_contents.get(previous_block).length;
				if (size_of_previous_block > 0) {
					compressor.setDictionary(block_id_to_contents.get(previous_block));
					block_id_to_contents.notifyAll();
				}
				else{
					;
				}
				is_first_block = false;
			}
		}

		compressor.setInput(blockBuf, 0, nBytes);
		int deflatedBytes = compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);


		if (deflatedBytes == 0 || deflatedBytes == -1){
			is_invalid_compressed_block = true;
		}
		else {
			synchronized (block_id_to_compressed_contents) {
				block_id_to_compressed_contents.put(cur_id, cmpBlockBuf);
				block_id_to_size.put(cur_id, deflatedBytes);
				block_id_to_compressed_contents.notifyAll();
				is_invalid_compressed_block = false;
			}
		}

	}

	ConcurrentHashMap<Integer, Integer> block_id_to_size;

	public SingleThreadedGZipCompressor(ConcurrentHashMap<Integer, byte[]> block_id_to_contents,
	ConcurrentHashMap<Integer, byte[]> block_id_to_compressed_contents, byte[] blockBuf, 
	ConcurrentHashMap<Integer, Integer> block_size, int cur_id, int nBytes, boolean is_first) {
		this.block_id_to_contents = block_id_to_contents;
		this.block_id_to_compressed_contents = block_id_to_compressed_contents;
		this.blockBuf = blockBuf;
		this.block_id_to_size = block_size;
		this.cur_id = cur_id;
		this.nBytes = nBytes;
		this.is_first = is_first;
	}

}

class write_to_output implements Runnable {
	
	public static PrintStream output_write = new PrintStream(System.out, true);
	ConcurrentHashMap<Integer, byte[]> block_id_to_compressed_contents;
	ConcurrentHashMap<Integer, Integer> block_id_to_size;

	public write_to_output(ConcurrentHashMap<Integer, byte[]> block_id_to_compressed_contents){
		this.block_id_to_compressed_contents = block_id_to_compressed_contents;
	}

	int total_num_blocks;
	static int CRCVAL = 0;
	static int tbytes = 0;

	public void count_total_number_of_blocks(int last_block) {
		total_num_blocks = last_block;
	}
	public void set_CRCValue(int CRC_value) {
		CRCVAL = CRC_value;
	}
	public void set_Total(int total_num_bytes) {
		tbytes = total_num_bytes;
	}

	// DONT NEED TO CHANGE THIS
	public static void writeHeader() throws IOException {
		output_write.write(new byte[] { (byte) constants.GZIP_MAGIC, // Magic number (short)
				(byte) (constants.GZIP_MAGIC >> 8), // Magic number (short)
				Deflater.DEFLATED, // Compression method (CM)
				0, // Flags (FLG)
				0, // Modification time MTIME (int)
				0, // Modification time MTIME (int)
				0, // Modification time MTIME (int)
				0, // Modification time MTIME (int)Sfil
				0, // Extra flags (XFLG)
				0 // Operating system (OS)
		});
		if (System.out.checkError()) {
			System.err.println("There was an error writing to output");
			Runtime.getRuntime().exit(1);
		}
	}

	public static void writeCompressorFinished(PrintStream output_write){
		Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
		byte[] cmpBlockBuf = new byte[constants.BLOCK_SIZE * 2];
		if (!compressor.finished()) {
			//compressor.finish()
			//while(true){
				//deflatedBytes= compress.deflate()
			//}
			
			compressor.finish();
			while (!compressor.finished()) {
				int deflatedBytes = compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.NO_FLUSH);
				if (deflatedBytes > 0) {
					output_write.write(cmpBlockBuf, 0, deflatedBytes);
					check_Error();
				}
			}
		}
	}
	public static void writeTrailer(long totalBytes, byte[] buf, int offset) throws IOException {
		writeInt((int) CRCVAL, buf, offset); // CRC-32 of uncompr. data
		writeInt((int) totalBytes, buf, offset + 4); // Number of uncompr. bytes	
		output_write.write(buf);
		if (System.out.checkError()) {
			System.err.println("There was an error writing to output");
			Runtime.getRuntime().exit(1);
		}
	}

	private static void writeInt(int i, byte[] buf, int offset) throws IOException {
		writeShort(i & 0xffff, buf, offset);
		writeShort((i >> 16) & 0xffff, buf, offset + 2);
	}

	private static void writeShort(int s, byte[] buf, int offset) throws IOException {
		buf[offset] = (byte) (s & 0xff);
		buf[offset + 1] = (byte) ((s >> 8) & 0xff);
	}

	public static void check_Error(){
		if (System.out.checkError()) {
			System.err.println("There was an error on the output write");
			Runtime.getRuntime().exit(1);
		}
	}


	public void run() {

		int cur_block_index = 0;
		try{
			writeHeader();
		}catch(IOException e){
			System.err.println("There was an error writing the header");
			Runtime.getRuntime().exit(1);
		}

		
		synchronized (block_id_to_compressed_contents) {
			while (true) {

				//while(block_it_to_compressed_contents.containsKey)
					//try{
						//block_id_to_contents
					//}
				while (!block_id_to_compressed_contents.containsKey(cur_block_index) && !block_id_to_size.containsKey(cur_block_index)) {
					try { block_id_to_compressed_contents.wait();
					} catch (InterruptedException e) { e.printStackTrace(); }
				}
				int temp = block_id_to_size.get(cur_block_index);
				output_write.write(block_id_to_compressed_contents.get(cur_block_index), 0, temp);
				check_Error();
				
				if (total_num_blocks == ++cur_block_index)
					break;
			}
		}
		writeCompressorFinished(output_write);
		
		byte[] trailerBuf = new byte[constants.TRAILER_SIZE];
		if (tbytes < 0) {
			tbytes = 0;
		}
		try{
			writeTrailer(tbytes, trailerBuf, 0);
		}catch(IOException e){
			System.err.println("There was an error writing the compression trailer");
			Runtime.getRuntime().exit(1);
		}
		

	}

}