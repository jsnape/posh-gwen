Feature "Failing scenarios" {
    Scenario "Just a given that fails" {
        Given {
            Assert-That $false
        }
    }

    Scenario "Just a when that fails" {
        When {
            Assert-That $false
        }
    }

    Scenario "Just a then that fails" {
        Then {
            Assert-That $false
        }
    }
}