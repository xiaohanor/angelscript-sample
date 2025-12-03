class UBasicAIAnimationTeleportingMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"AnimationMovement");	
	default TickGroupOrder = 45;

	UHazeCharacterSkeletalMeshComponent Mesh;
	UTeleportingMovementData TeleportingMovement;

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
		Super::Setup();
		Mesh = Cast<UHazeCharacterSkeletalMeshComponent>(Cast<AHazeCharacter>(Owner).Mesh);
		TeleportingMovement = Cast<UTeleportingMovementData>(Movement);

		// TODO: This might be a bit of a blunt instrument, might need to set these per animation request
		MoveRatioSettings.XAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferXThenYZ;
		MoveRatioSettings.YAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferYThenXZ;
		MoveRatioSettings.ZAxis = EHazeMoveRatioAxisSetting::MoveRatioAxisSetting_PreferZThenXY;
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupTeleportingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(TeleportingMovement);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!AnimComp.HasMovementRequest())	
			return false;
		if (!MoveSettings.bUseTeleportingAnimationMovement)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!AnimComp.HasMovementRequest())	
			return true;
		if (!MoveSettings.bUseTeleportingAnimationMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnAnimEvaluated");
	}

	UFUNCTION()
	private void OnAnimEvaluated(UHazeSkeletalMeshComponentBase SkelMeshComp)
	{
		// TODO: Here we can check which anims are active
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mesh.OnPostAnimEvalComplete.Unbind(this, n"OnAnimEvaluated"); 
		
		// Next move will be a new one
		CurrentTag = NAME_None;
		CurrentSubTag = NAME_None;
	}

	void ComposeMovement(float DeltaTime) override
	{	
		if (IsNewMove())
			InitializeMove(DeltaTime);
		
		// FVector NewRequestedMove = AnimComp.GetMovementRequest();
		// if (!NewRequestedMove.Equals(RequestedMove, 0.01))
		// {
		// 	for (int i = 0; i < 3; i++)
		// 	{
		// 		if (RequestedMove[i] != 0)
		// 			AccumulatedAnimMovement[i] *= NewRequestedMove[i] / RequestedMove[i];
		// 	} 

		// 	RequestedMove = NewRequestedMove;
		// }	

		FVector AnimMove = GetCurrentMoveDelta(DeltaTime);
		Movement.AddDelta(AnimMove);

		// Turn towards focus, if any
		if (DestinationComp.Focus.IsValid())
		  	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

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
			float NextPosition = AnimData.CurrentPosition + DeltaTime * Playrate;
			FVector LocalDelta = AnimData.Sequence.GetDeltaMoveForMoveRatioWithSettings(AccumulatedAnimMovement, NextPosition, RequestedMove, AnimData.Sequence.PlayLength, MoveRatioSettings);

			if (AnimComp.IsUsingLocalMovementRotation())
				return Mesh.WorldTransform.TransformVectorNoScale(LocalDelta);
			else
				return InitialTransform.TransformVectorNoScale(LocalDelta);
		} 
		return FVector::ZeroVector;
	}
}
