class UIslandZoomotronDamageReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandZoomotronSettings ZoomtronSettings;

	FHazeAcceleratedFloat HackPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ZoomtronSettings = UIslandZoomotronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		HackPitch.SnapTo(0.0);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		HealthComp.TakeDamage(ZoomtronSettings.DefaultDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);
		DamageFlash::DamageFlashActor(Owner, 0.1);
	}


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// HACK: pitch mesh as temp anim
		UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		FRotator MeshRot = Mesh.RelativeRotation;
		if (IsActive())
		{
			float Pitch = HackPitch.SpringTo(40.0, 500.0, 0.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
		else
		{
			float Pitch = HackPitch.AccelerateTo(0.0, 1.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ZoomtronSettings.HurtReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, ZoomtronSettings.HurtReactionDuration);

		UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackPitch.SnapTo(Mesh.RelativeRotation.Pitch);
	}
}
