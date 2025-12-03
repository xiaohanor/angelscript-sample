class UJetskiDriverSequenceCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -80;	// Tick early, but after UJetskiDriverCapability and UJetskiDriverAttachCapability

	UJetskiDriverComponent DriverComp;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.bIsParticipatingInCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.bIsParticipatingInCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DriverComp.Jetski.BlockCapabilities(CapabilityTags::Movement, this);
		DriverComp.Jetski.BlockCapabilities(CapabilityTags::MovementInput, this);
		DriverComp.Jetski.BlockCapabilities(CapabilityTags::Input, this);
		DriverComp.Jetski.BlockCapabilities(CapabilityTags::GameplayAction, this);
		DriverComp.Jetski.BlockCapabilities(CapabilityTags::Death, this);

		DriverComp.Jetski.SkelMesh.SetRelativeLocation(FVector::ZeroVector);

		PreviousLocation = DriverComp.Jetski.SkelMesh.GetSocketLocation(n"Base");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto DefaultJetski = Cast<AJetski>(DriverComp.Jetski.Class.DefaultObject);

		DriverComp.Jetski.UnblockCapabilities(CapabilityTags::Movement, this);
		DriverComp.Jetski.UnblockCapabilities(CapabilityTags::MovementInput, this);
		DriverComp.Jetski.UnblockCapabilities(CapabilityTags::Input, this);
		DriverComp.Jetski.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		DriverComp.Jetski.UnblockCapabilities(CapabilityTags::Death, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
		{
			TickInactive(DeltaTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector CurrentLocation = DriverComp.Jetski.SkelMesh.GetSocketLocation(n"Base");
		FVector FrameVelocity = (CurrentLocation - PreviousLocation) / DeltaTime;
		FrameVelocity = FrameVelocity.GetClampedToMaxSize(DriverComp.Jetski.MoveComp.MovementSettings.MaxSpeed);
		DriverComp.Jetski.SetActorVelocity(FrameVelocity);
		PreviousLocation = CurrentLocation;
	}

	void TickInactive(float DeltaTime)
	{
		float Alpha = Math::Saturate(DeactiveDuration / 2.0);

		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		auto DefaultJetski = Cast<AJetski>(DriverComp.Jetski.Class.DefaultObject);
		const FVector TargetRelativeLocation = DefaultJetski.SkelMesh.RelativeLocation;
		const FVector RelativeLocation = Math::Lerp(
			FVector::ZeroVector,
			TargetRelativeLocation,
			Alpha
		);

		DriverComp.Jetski.SkelMesh.SetRelativeLocation(RelativeLocation);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		const FVector CurrentLocation = DriverComp.Jetski.SkelMesh.GetSocketLocation(n"Base");
		TemporalLog.DirectionalArrow("Velocity", CurrentLocation, DriverComp.Jetski.ActorVelocity);
	}
#endif
};