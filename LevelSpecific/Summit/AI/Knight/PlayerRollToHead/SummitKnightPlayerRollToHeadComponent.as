enum EKnightPlayerRollToHeadType
{
	None,
	JumpToHead,
	RollUpBlades,
}

class USummitKnightPlayerRollToHeadComponent : UActorComponent
{
	EKnightPlayerRollToHeadType Type = EKnightPlayerRollToHeadType::None;
	UHazeSkeletalMeshComponentBase KnightMesh = nullptr;
	bool bWillSmash = false;
};
