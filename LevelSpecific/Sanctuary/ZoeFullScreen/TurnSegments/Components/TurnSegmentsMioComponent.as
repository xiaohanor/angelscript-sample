struct FTurnSegmentConstraintChain
{
    TArray<FTurnSegmentConstraint> Links;
}

struct FTurnSegmentResponseChain
{
    TArray<UTurnSegmentResponseComponent> Links;
}

class UTurnSegmentsMioComponent : UActorComponent
{
    TArray<UTurnSegmentResponseComponent> ResponseComponents;
    TArray<FTurnSegmentConstraintChain> ConstraintChains;
}