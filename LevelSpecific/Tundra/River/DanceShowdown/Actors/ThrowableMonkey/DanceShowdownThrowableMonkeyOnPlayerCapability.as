class UDanceShowdownThrowableMonkeyOnPlayerCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	FHazeAcceleratedFloat ShakeOffset;
	
	float OnFaceDuration = 0;
	float OnFaceShakeStrength = 80;
	float OnFaceShakeFrequency = 2000;
	FVector OriginalRelativeLocation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::OnFace)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::OnFace)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.TargetPlayer.SetMonkeyOnFace(Monkey);
		Monkey.MeshComp.PlaySlotAnimation(Monkey.OnPlayerAnim);
				
		Monkey.AttachToComponent(Monkey.TargetPlayerMesh, n"Head", EAttachmentRule::KeepRelative, EAttachmentRule::KeepRelative, EAttachmentRule::KeepWorld, false);
		OriginalRelativeLocation = Monkey.RelativeOffsetToHead;
		Monkey.SetActorRelativeLocation(OriginalRelativeLocation);
		Monkey.SetActorRelativeRotation(FRotator(-30,180,0));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//ShakeOffset.SpringTo(Monkey.WiggleInput, OnFaceShakeFrequency, 0.0, DeltaTime);
		//Monkey.SetActorRelativeLocation(OriginalRelativeLocation + FVector(0, OnFaceShakeStrength * ShakeOffset.Value, 0));
	}
};