class UGravityBikeSplineDriverSequenceCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	AHazePlayerCharacter Player;
	UGravityBikeSplineDriverComponent DriverComp;
	UGravityBikeBladePlayerComponent BladeComp;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();

		GravityBike.BlockCapabilities(GravityBikeSpline::Tags::GravityBikeSpline, this);
		GravityBike.BlockCapabilities(CapabilityTags::Movement, this);
		GravityBike.BlockCapabilities(CapabilityTags::MovementInput, this);
		GravityBike.BlockCapabilities(CapabilityTags::Input, this);
		GravityBike.BlockCapabilities(CapabilityTags::GameplayAction, this);
		GravityBike.BlockCapabilities(CapabilityTags::Camera, this);
		GravityBike.BlockCapabilities(CapabilityTags::Death, this);

		GravityBike.MeshPivot.SetRelativeTransform(FTransform::Identity);
		GravityBike.SkeletalMesh.SetRelativeTransform(FTransform::Identity);

		PreviousLocation = GravityBike.SkeletalMesh.GetSocketLocation(n"Base");
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();

		const AGravityBikeSpline DefaultGravityBike = Cast<AGravityBikeSpline>(GravityBike.Class.DefaultObject);
		GravityBike.MeshPivot.SetRelativeTransform(DefaultGravityBike.MeshPivot.RelativeTransform);
		GravityBike.SkeletalMesh.SetRelativeTransform(DefaultGravityBike.SkeletalMesh.RelativeTransform);

		GravityBike.UnblockCapabilities(GravityBikeSpline::Tags::GravityBikeSpline, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Movement, this);
		GravityBike.UnblockCapabilities(CapabilityTags::MovementInput, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Input, this);
		GravityBike.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Camera, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Death, this);

		//Player.ApplyBlendToCurrentView(0.2);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlocked())
		{
			AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();
			FVector NewLocation = GravityBike.SkeletalMesh.GetSocketLocation(n"Base");
			FVector Velocity = (NewLocation - PreviousLocation) / DeltaTime;
			GravityBike.SetActorVelocity(Velocity);
			PreviousLocation = NewLocation;

			GravityBike.AnimationData.bIsThrottling = true;

			TEMPORAL_LOG(this).DirectionalArrow("Velocity", GravityBike.ActorCenterLocation, Velocity);
		}
	}
};