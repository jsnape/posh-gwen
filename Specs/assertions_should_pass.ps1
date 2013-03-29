Feature "Assert-That assertions" {
    Scenario "Assert that true passes" {
        Then {
            Assert-That $true
        }
    }

    Scenario "Assert that false fails" {
        Then {
            Should-Fail {
                Assert-That $false
            }
        }
    }

    Scenario "Assert that null fails" {
        Then {
            Should-Fail {
                Assert-That $null
            }
        }
    }
}

Feature "Assert-Equal assertions" {
    Scenario "Assert that 1 equals 1" {
        Then {
            Assert-Equal 1 1
        }
    }

    Scenario "Assert that true equals true" {
        Then {
            Assert-Equal $true $true
        }
    }

    Scenario "Assert that true not equal false" {
        Then {
            Should-Fail {
                Assert-Equal $true $false
            }
        }
    }
}

Feature "Should-Fail assertions" {

    Scenario "Should-Fail negates test result" {
        Then {
            Should-Fail {
                throw "A guaranteed exception"
            }
        }
    }
}

Feature "Fail-Test assertions" {

    Scenario "Fail-Test always fails" {
        Then {
            Should-Fail {
                Fail-Test
            }
        }
    }
}