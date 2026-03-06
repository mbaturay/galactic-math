import Foundation

enum MathTopic: String, CaseIterable, Codable {
    // Kindergarten
    case counting1to10
    case counting11to20
    case comparingNumbers
    case additionWithin5
    case subtractionWithin5
    // Grade 1
    case additionWithin10
    case subtractionWithin10
    case additionWithin20
    case subtractionWithin20
    case placeValue
    // Grade 2
    case additionWithin100
    case subtractionWithin100
    case skipCounting
    case introMultiplication
    case timeAndMeasurement
    // Grade 3
    case multiplicationBasic
    case multiplicationMedium
    case multiplicationAdvanced
    case divisionBasic
    case fractionsIntro
    // Grade 4
    case multiDigitMultiplication
    case longDivision
    case equivalentFractions
    case addSubtractFractions
    case decimalsIntro
    // Grade 5
    case multiplyFractions
    case divideFractions
    case decimalOperations
    case volumeBasics
    case coordinatePlane
    // Grade 6
    case ratiosAndRates
    case percentages
    case negativeNumbers
    case oneStepEquations
    case complexArea
    // Grade 7
    case twoStepEquations
    case proportionalRelationships
    case probability
    case geometry
    case mixedChallenge

    var narrativePrompt: String {
        switch self {
        case .counting1to10, .counting11to20:
            return "How many are there?"
        case .comparingNumbers:
            return "Which number is bigger?"
        case .additionWithin5, .additionWithin10, .additionWithin20, .additionWithin100:
            return "What is the sum?"
        case .subtractionWithin5, .subtractionWithin10, .subtractionWithin20, .subtractionWithin100:
            return "What is the difference?"
        case .placeValue:
            return "What digit is it?"
        case .skipCounting:
            return "What comes next?"
        case .introMultiplication, .multiplicationBasic, .multiplicationMedium, .multiplicationAdvanced, .multiDigitMultiplication:
            return "What is the product?"
        case .timeAndMeasurement:
            return "What time is it?"
        case .divisionBasic, .longDivision:
            return "What is the quotient?"
        case .fractionsIntro, .equivalentFractions, .addSubtractFractions, .multiplyFractions, .divideFractions:
            return "What is the answer?"
        case .decimalsIntro, .decimalOperations:
            return "What is the answer?"
        case .volumeBasics:
            return "What is the volume?"
        case .coordinatePlane:
            return "What is the distance?"
        case .ratiosAndRates, .proportionalRelationships:
            return "What is the missing value?"
        case .percentages:
            return "What is the result?"
        case .negativeNumbers:
            return "What is the answer?"
        case .oneStepEquations, .twoStepEquations:
            return "What is the value of x?"
        case .complexArea:
            return "What is the area?"
        case .probability:
            return "What is the probability?"
        case .geometry:
            return "What is the answer?"
        case .mixedChallenge:
            return "Solve it!"
        }
    }

    var displayName: String {
        switch self {
        case .counting1to10:           return "Counting 1-10"
        case .counting11to20:          return "Counting 11-20"
        case .comparingNumbers:        return "Comparing Numbers"
        case .additionWithin5:         return "Addition within 5"
        case .subtractionWithin5:      return "Subtraction within 5"
        case .additionWithin10:        return "Addition within 10"
        case .subtractionWithin10:     return "Subtraction within 10"
        case .additionWithin20:        return "Addition within 20"
        case .subtractionWithin20:     return "Subtraction within 20"
        case .placeValue:              return "Place Value"
        case .additionWithin100:       return "Addition within 100"
        case .subtractionWithin100:    return "Subtraction within 100"
        case .skipCounting:            return "Skip Counting"
        case .introMultiplication:     return "Intro to Multiplication"
        case .timeAndMeasurement:      return "Time & Measurement"
        case .multiplicationBasic:     return "Multiplication x2,x5,x10"
        case .multiplicationMedium:    return "Multiplication x3,x4"
        case .multiplicationAdvanced:  return "Multiplication x6-x9"
        case .divisionBasic:           return "Division Basics"
        case .fractionsIntro:          return "Fractions Intro"
        case .multiDigitMultiplication:return "Multi-digit Multiplication"
        case .longDivision:            return "Long Division"
        case .equivalentFractions:     return "Equivalent Fractions"
        case .addSubtractFractions:    return "Add & Subtract Fractions"
        case .decimalsIntro:           return "Decimals Intro"
        case .multiplyFractions:       return "Multiplying Fractions"
        case .divideFractions:         return "Dividing Fractions"
        case .decimalOperations:       return "Decimal Operations"
        case .volumeBasics:            return "Volume Basics"
        case .coordinatePlane:         return "Coordinate Plane"
        case .ratiosAndRates:          return "Ratios & Rates"
        case .percentages:             return "Percentages"
        case .negativeNumbers:         return "Negative Numbers"
        case .oneStepEquations:        return "One-Step Equations"
        case .complexArea:             return "Area of Complex Shapes"
        case .twoStepEquations:        return "Two-Step Equations"
        case .proportionalRelationships: return "Proportional Relationships"
        case .probability:             return "Probability"
        case .geometry:                return "Geometry"
        case .mixedChallenge:          return "Mixed Challenge"
        }
    }
}
