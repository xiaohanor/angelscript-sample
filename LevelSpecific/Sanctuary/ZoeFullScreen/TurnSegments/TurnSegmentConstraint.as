struct FTurnSegmentConstraint
{
    private UTurnSegmentResponseComponent First;
    private UTurnSegmentResponseComponent Second;
    private float ConstrainAngle;

    FTurnSegmentConstraint(UTurnSegmentResponseComponent InFirst, UTurnSegmentResponseComponent InSecond, float InConstraintAngle)
    {
        First = InFirst;
        Second = InSecond;
        ConstrainAngle = InConstraintAngle;
    }

    void UpdateConstraint(ETurnSegmentConstraintIndex Priority) const
    {
        if(GetDistance() < ConstrainAngle)
            return; // The angle is fine, don't constrain

        // Direction of the "hit"
        float OffsetDir = Math::Sign(GetDifference());

        // Only change rotation on the segment that does not have priority
        if(Priority == ETurnSegmentConstraintIndex::First)
        {
            // Always set rotation ...
            Second.Rotation.Roll = First.Rotation.Roll - OffsetDir * ConstrainAngle;
            
            // ... but only set rotation if our velocity is lower than the priority segment
            if(GetAHasHigherVelocityThanB(First, Second, OffsetDir))
                Second.Velocity = First.Velocity;
        }
        else
        {
            // Always set rotation ...
            First.Rotation.Roll = Second.Rotation.Roll + OffsetDir * ConstrainAngle;

            // ... but only set rotation if our velocity is lower than the priority segment
            if(GetAHasHigherVelocityThanB(Second, First, -OffsetDir))
                First.Velocity = Second.Velocity;
        }
    }

    float GetDifference() const
    {
        return First.Rotation.Roll - Second.Rotation.Roll;
    }

    float GetDistance() const
    {
        return Math::Abs(GetDifference());
    }

    ETurnSegmentConstraintIndex IsConstraining(UTurnSegmentResponseComponent InFirst) const
    {
        if (First == InFirst)
            return ETurnSegmentConstraintIndex::First;
        else if(Second == InFirst)
            return ETurnSegmentConstraintIndex::Second;
        else
            return ETurnSegmentConstraintIndex::None;
    }

    FString ToString() const
    {
        return "First: " + First.Owner.GetName().ToString() + ", Second: " + Second.Owner.GetName().ToString();
    }

    UTurnSegmentResponseComponent GetFirst() const
    {
        return First;
    }

    UTurnSegmentResponseComponent GetSecond() const
    {
        return Second;
    }

    bool GetAHasHigherVelocityThanB(UTurnSegmentResponseComponent A, UTurnSegmentResponseComponent B, float Direction) const
    {
        if(Direction > 0.0)
            return A.Velocity > B.Velocity;
        else
            return A.Velocity < B.Velocity;
    }
}

enum ETurnSegmentConstraintIndex
{
    None, First, Second
}