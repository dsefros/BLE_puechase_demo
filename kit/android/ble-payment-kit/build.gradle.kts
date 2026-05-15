plugins {
    kotlin("jvm") version "2.0.21"
}

group = "ru.paymentguide.blepaymentkit"
version = "0.1.0"

kotlin {
    jvmToolchain(17)
}

tasks.test {
    useJUnitPlatform()
}

dependencies {
    testImplementation(kotlin("test"))
}
