package com.amalitech.ecr;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@GetMapping("/")
	public String hello() {
		return "Hello from AmaliTech ECR lab! Running in a container pushed via GitHub Actions OIDC.";
	}

}
