UCLASS(Abstract)
class ULightBirdEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;
	
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ULightBirdUserComponent UserComp;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeSphereComponent HazeSphere;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UPointLightComponent Light;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	FHazeAcceleratedFloat Glow;
	FLinearColor DefaultColour = FLinearColor::Black;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner);
		Player = CompanionComp.Player;

		UserComp = ULightBirdUserComponent::Get(Player);

		Mesh = UserComp.Companion.Mesh;
		Light = UserComp.Companion.PointLightComponent;
		HazeSphere = UserComp.Companion.HazeSphereComponent;
//		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
//		HazeSphere = UHazeSphereComponent::Get(Owner);
//		Light = UPointLightComponent::Get(Owner);
	}

	// Called when the bird attaches to the player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Absorbed() { }

	// Called when the bird starts exiting the player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReleaseStarted() { }

	// Called when the bird has finished exiting the player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReleaseStopped() { }

	// Called when the bird starts launching.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchStarted() { }

	// Called when the bird finishes launching.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchFailedToAttach() { }

	// Called when the bird attaches to it's target.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachedTarget() { }

	// Called when the bird attaches to it's target.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachedTargetStopped() { }

	// Called when the bird starts recalling while instant recall is disabled.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RecallStarted() { }

	// Called when the bird finishes recalling while instant recall is disabled.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RecallStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RecallReturned() { }

	// Called when the bird starts illuminating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Illuminated() { }

	// Called when the bird stops illuminating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Unilluminated() { }

	// Called when the bird is being recalled for lantern duty
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LanternRecallStarted() { }

	// Called when the bird stops being recalled for lantern duty (either being attached or not)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LanternRecallStopped() { }

	// Called when the bird attaches to player hand for lantern duty.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LanternAttachedStarted() { }

	// Called when the bird detaches from lantern position.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LanternAttachedStopped() { }

	// Called when teleported in behind player camera (usually from player being teleported)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WatsonTeleport() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionIntroStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionIntroReachedPlayer() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InvestigateStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InvestigateStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InvestigateAttachStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void InvestigateAttachStopped() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowSlidingDiscStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowSlidingDiscStop() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowCentipedeStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompanionFollowCentipedeStop() { }

	UFUNCTION(BlueprintPure)
	bool IsIlluminating() const
	{
		return CompanionComp.UserComp.IsIlluminating();
	}

	UFUNCTION(BlueprintPure)
	float GetIlluminationRadius() const property
	{
		return LightBird::Illumination::Radius;
	}

	UFUNCTION(BlueprintCallable)
	void UpdateGlow(float GlowFactor, float ChangeDuration, float DeltaTime)
	{
		if (CompanionComp == nullptr)
			return;
		Glow.AccelerateTo(GlowFactor, ChangeDuration, DeltaTime);
		if (CompanionComp.GlowMaterial != nullptr)
		{
			CompanionComp.GlowMaterial.SetScalarParameterValue(n"Emissive", Glow.Value);

			if (DefaultColour == FLinearColor::Black)
				DefaultColour = CompanionComp.GlowMaterial.GetVectorParameterValue(n"Color");
			FLinearColor Color = DefaultColour * Glow.Value;
			Color.A = DefaultColour.A;
			CompanionComp.GlowMaterial.SetVectorParameterValue(n"Color", Color);
		}
	}

	UFUNCTION(BlueprintPure)
	ELightBirdState GetState() const
	{
		return CompanionComp.UserComp.State;
	}
}