[ref] $global:givenCount = 0;
[ref] $global:whenCount = 0;
[ref] $global:thenCount = 0;

Feature "Given, when, then should execute in phase order" {
    Scenario "Scenario 1" {
        Given {
            $givenCount.value++
            Assert-Equal 0 $whenCount.value
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        When {
            $whenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        Then {
            $thenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-That ($whenCount.value -gt 0)
        }.GetNewClosure()
    }

    Scenario "Scenario 2" {
        Given {
            $givenCount.value++
            Assert-Equal 0 $whenCount.value
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        When {
            $whenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        Then {
            $thenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-That ($whenCount.value -gt 0)
        }.GetNewClosure()
    }
}

Feature "Given, when, then should execute in phase order, part 2" {
    Scenario "Scenario 3" {
        Given {
            $givenCount.value++
            Assert-Equal 0 $whenCount.value
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        When {
            $whenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-Equal 0 $thenCount.value
        }.GetNewClosure()

        Then {
            $thenCount.value++
            Assert-That ($givenCount.value -gt 0)
            Assert-That ($whenCount.value -gt 0)
        }.GetNewClosure()
    }
}