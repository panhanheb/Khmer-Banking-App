package com.khmerbank;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class KhmerBankApplication {

    public static void main(String[] args) {
        SpringApplication.run(KhmerBankApplication.class, args);
    }
}
