class USmasherAnimationMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AnimationMovement");	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USummitSmasherJumpAttackComponent JumpAttackComp;
	UBasicAIMovementSettings MoveSettings;
	USteppingMovementData Movement;

    FVector CustomVelocity;
	FVector PrevLocation;

	UHazeCharacterSkeletalMeshComponent Mesh;

	FName CurrentTag = NAME_None;
	FName CurrentSubTag = NAME_None;
	FVector RequestedMove;
	FVector AccumulatedAnimMovement;
	FTransform InitialTransform;
	float StartTime;
	FHazeMoveRatioSettings MoveRatioSettings;		
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		JumpAttackComp = USummitSmasherJumpAttackComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		Mesh = Cast<UHazeCharacterSkeletalMeshComponent>(Cast<AHazeCharacter>(Owner).Mesh);
		Movement = Cast<USteppingMovementData>(Movement);

		MoveRatioSettings.XAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferXThenYZ;
		MoveRatioSettings.YAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferYThenXZ;
		MoveRatioSettings.ZAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferZThenXY;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!AnimComp.HasMovementRequest())	
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!AnimComp.HasMovementRequest())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Next move will be a new one
		CurrentTag = NAME_None;
		CurrentSubTag = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (IsNewMove())
			InitializeMove(DeltaTime);
		
		FVector NewRequestedMove = AnimComp.GetMovementRequest();
		if (!NewRequestedMove.Equals(RequestedMove, 0.01))
		{
			for (int i = 0; i < 3; i++)
			{
				if (RequestedMove[i] != 0)
					AccumulatedAnimMovement[i] *= NewRequestedMove[i] / RequestedMove[i];
			} 

			RequestedMove = NewRequestedMove;
		}	

		FVector AnimMove = GetCurrentMoveDelta(DeltaTime);
		Movement.AddDelta(AnimMove);

		if (JumpAttackComp.ExtraVerticalVelocity != 0.0)
			Movement.AddVelocity(Owner.ActorUpVector * JumpAttackComp.ExtraVerticalVelocity);

		// Turn towards focus, if any
		if (DestinationComp.Focus.IsValid())
		  	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
		Movement.AddGravityAcceleration();
	}

	bool IsNewMove()
	{
		if (AnimComp.GetFeatureTag() != CurrentTag)
			return true;
		if (AnimComp.GetSubFeatureTag() != CurrentSubTag)
			return true;
		return false;
	}

	void InitializeMove(float DeltaTime)
	{
		CurrentTag = AnimComp.GetFeatureTag(); 
		CurrentSubTag = AnimComp.GetSubFeatureTag();

		StartTime = Time::GameTimeSeconds;
		InitialTransform = Mesh.WorldTransform;

		RequestedMove = AnimComp.GetMovementRequest();

		// Initialize accumulated movement by current velocity (since we will not have an animation for the first update)
		AccumulatedAnimMovement = InitialTransform.InverseTransformVectorNoScale(AnimComp.Owner.GetActorVelocity()) * DeltaTime;
	}

	FVector GetCurrentMoveDelta(float DeltaTime)
	{		
		float RequestedDuration = -1.0;
		if (AnimComp.HasActionDurationRequest())
			RequestedDuration = AnimComp.GetActionDurationRequest().GetTotal();
		else if (AnimComp.HasDurationRequest())
			RequestedDuration = AnimComp.GetDurationRequest();
		TArray<FHazePlayingAnimationData> Animations;
		Mesh.GetCurrentlyPlayingAnimations(Animations);
		for (FHazePlayingAnimationData AnimData : Animations)
		{
			if (AnimData.Sequence == nullptr)
				continue;

			// TODO: Assume we only have a single animation, will have to fix properly later
			float Playrate = AnimComp.GetSequencePlayRate(AnimData.Sequence);
			float NextPosition = Math::Min(AnimData.CurrentPosition + DeltaTime * Playrate, AnimData.Sequence.PlayLength);
			FVector LocalDelta = AnimData.Sequence.GetDeltaMoveForMoveRatioWithSettings(AccumulatedAnimMovement, NextPosition, RequestedMove, AnimData.Sequence.PlayLength, MoveRatioSettings);

			if (AnimComp.IsUsingLocalMovementRotation())
				return Mesh.WorldTransform.TransformVectorNoScale(LocalDelta);
			else
				return InitialTransform.TransformVectorNoScale(LocalDelta);
		} 
		return FVector::ZeroVector;
	}
}
