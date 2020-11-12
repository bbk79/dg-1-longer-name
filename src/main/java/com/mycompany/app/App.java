package com.mycompany.app;

import java.util.Random;

/**
 * Hello world!
 *
 */
public class App
{
    public static void main( String[] args )
    {
        System.out.println( "Hello World!" );
    }

    public String generateNotSoSecretToken() {
        Random r = new Random();
        return Long.toHexString(r.nextLong());
    }
}
