package agri.change.wkhtmltopdf;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

// import javafx.stage.Screen;

@SpringBootApplication
@RestController
@RequestMapping("/wkHtmltoPdf")
public class WkHtmlApplication {
	@Value("${wkhtmltopdf.location}")
	private String wkhtmltopdfPath;
	public static void main(String[] args) {
		SpringApplication.run(WkHtmlApplication.class, args);
	}
	
	@PostMapping(value = "/generatePdf")
	public String generatePDF(@RequestBody() RequestDTO request) {
		try {
			Process wkhtml; // Create uninitialized process
			Path path = Paths.get(wkhtmltopdfPath);
			String command = path + " --enable-local-file-access --page-size A4 " + request.getSrc() + " "
					+ request.getDestination(); // Desired command
			System.out.println("command -> " + command);
			wkhtml = Runtime.getRuntime().exec(command); // Start process
			wkhtml.waitFor(); // Allow process to run
			return "success";
		} catch (Exception e) {
			System.out.println("failed to generate pdf" + e.getMessage());
			return "failed";
		}
	}
}

class RequestDTO {
	String src;
	String destination;

	public String getSrc() {
		return src;
	}

	public void setSrc(String src) {
		this.src = src;
	}

	public String getDestination() {
		return destination;
	}

	public void setDestination(String destination) {
		this.destination = destination;
	}

}