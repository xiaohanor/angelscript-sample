class UGravityBikeFreeDriverSequenceCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	AHazePlayerCharacter Player;
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	AGravityBikeFree GravityBike;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		
		GravityBike = GravityBikeFree::GetGravityBike(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFree, this);
		GravityBike.BlockCapabilities(CapabilityTags::Movement, this);
		GravityBike.BlockCapabilities(CapabilityTags::MovementInput, this);
		GravityBike.BlockCapabilities(CapabilityTags::Input, this);
		GravityBike.BlockCapabilities(CapabilityTags::GameplayAction, this);
		GravityBike.BlockCapabilities(CapabilityTags::Camera, this);
		GravityBike.BlockCapabilities(CapabilityTags::Death, this);
		GravityBike.BlockCapabilities(CapabilityTags::BlockedByCutscene, this);

		GravityBike.MeshPivot.SetRelativeTransform(FTransform::Identity);
		GravityBike.SkeletalMesh.SetRelativeTransform(FTransform::Identity);

		PreviousLocation = GravityBike.SkeletalMesh.GetSocketLocation(n"Base");
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		const AGravityBikeFree DefaultGravityBike = Cast<AGravityBikeFree>(GravityBike.Class.DefaultObject);
		GravityBike.MeshPivot.SetRelativeTransform(DefaultGravityBike.SkeletalMesh.RelativeTransform);
		GravityBike.SkeletalMesh.SetRelativeTransform(DefaultGravityBike.SkeletalMesh.RelativeTransform);

		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFree, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Movement, this);
		GravityBike.UnblockCapabilities(CapabilityTags::MovementInput, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Input, this);
		GravityBike.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Camera, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Death, this);
		GravityBike.UnblockCapabilities(CapabilityTags::BlockedByCutscene, this);

		CameraDataComp.AccCameraRotation.SnapTo(Player.ViewRotation.Quaternion());
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlocked())
		{
			FVector NewLocation = GravityBike.SkeletalMesh.GetSocketLocation(n"Base");
			FVector Velocity = (NewLocation - PreviousLocation) / DeltaTime;
			GravityBike.SetActorVelocity(Velocity);
			PreviousLocation = NewLocation;
		}
	}
};