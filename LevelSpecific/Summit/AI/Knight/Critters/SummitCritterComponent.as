class USummitCritterComponent : UActorComponent
{
	USkeletalMeshComponent LatchOnToMesh = nullptr;
	FName LatchOnToSocket = NAME_None;
	float LatchOnSpeed = 0.0;
	bool bLatchOnComplete = false;

	void LatchOn(AHazePlayerCharacter Player, FName Socket)
	{
		LatchOnToMesh = UPlayerTeenDragonComponent::Get(Player).DragonMesh;
		LatchOnToSocket = Socket;
		bLatchOnComplete = false;
	}

	void ClearLatchOn()
	{
		LatchOnToMesh = nullptr;
		LatchOnToSocket = NAME_None;
		LatchOnSpeed = 0.0;
		bLatchOnComplete = false;
	}

	void LatchOnMove(float Speed)
	{
		LatchOnSpeed = Speed;
	}

	void CompleteLatchOn()
	{
		bLatchOnComplete = true;
	}
};
