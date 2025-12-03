enum ESummitGeyserBlockerDirection
{
	Down,
	Left,
	Up,
	Right,
	MAX
}

class ASummitGeyserBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitGeyserBlockerRotateCapability);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitGeyser BottomLeftGeyser;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitGeyser BottomRightGeyser;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitGeyser TopLeftGeyser;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitGeyser TopRightGeyser;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GeyserDistanceFromMiddle = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotateDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotateDelay = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRotateClockWise = true;

	ESummitGeyserBlockerDirection BlockerDirection = ESummitGeyserBlockerDirection::Down;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(BottomLeftGeyser != nullptr)
		{
			BottomLeftGeyser.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
			FRotator OffsetRotation = ActorRotation;
			OffsetRotation.Yaw += 225;
			FVector TargetLocation = ActorLocation + (OffsetRotation.ForwardVector * GeyserDistanceFromMiddle);
			TargetLocation.Z = BottomLeftGeyser.ActorLocation.Z;
			BottomLeftGeyser.ActorLocation = TargetLocation; 
		}
		if(BottomRightGeyser != nullptr)
		{
			BottomRightGeyser.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
			FRotator OffsetRotation = ActorRotation;
			OffsetRotation.Yaw += 135;
			FVector TargetLocation = ActorLocation + (OffsetRotation.ForwardVector * GeyserDistanceFromMiddle);
			TargetLocation.Z = BottomRightGeyser.ActorLocation.Z;
			BottomRightGeyser.ActorLocation = TargetLocation;
		}
		if(TopLeftGeyser != nullptr)
		{
			TopLeftGeyser.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
			FRotator OffsetRotation = ActorRotation;
			OffsetRotation.Yaw += 315;
			FVector TargetLocation = ActorLocation + (OffsetRotation.ForwardVector * GeyserDistanceFromMiddle);
			TargetLocation.Z = TopLeftGeyser.ActorLocation.Z;
			TopLeftGeyser.ActorLocation = TargetLocation;
		} 
		if(TopRightGeyser != nullptr)
		{
			TopRightGeyser.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
			FRotator OffsetRotation = ActorRotation;
			OffsetRotation.Yaw += 45;
			FVector TargetLocation = ActorLocation + (OffsetRotation.ForwardVector * GeyserDistanceFromMiddle);
			TargetLocation.Z = TopRightGeyser.ActorLocation.Z;
			TopRightGeyser.ActorLocation = TargetLocation;
		}
	}
};