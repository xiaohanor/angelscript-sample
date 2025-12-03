class UCoastTrainDroneDamageReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UCoastTrainDroneSettings Settings;
	UCoastShoulderTurretGunResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastTrainDroneSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);		
		ResponseComp = UCoastShoulderTurretGunResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnBulletHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(FCoastShoulderTurretBulletHitParams Params)
	{
		HealthComp.TakeDamage(Params.Damage * Settings.DamageFromProjectilesFactor, EDamageType::Projectile, Params.PlayerInstigator);
		UCoastTrainDroneEffectHandler::Trigger_OnDamage(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > Settings.DamageReactionDuration * 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.DamageReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, Settings.DamageReactionDuration);

		// HACK: pitch mesh as temp anim
		UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackPitch.SnapTo(Mesh.RelativeRotation.Pitch);
	}

	FHazeAcceleratedFloat HackPitch;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// HACK: pitch mesh as temp anim
		UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		FRotator MeshRot = Mesh.RelativeRotation;
		if (IsActive())
		{
			float Pitch = HackPitch.SpringTo(30.0, 500.0, 0.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
		else
		{
			float Pitch = HackPitch.AccelerateTo(0.0, 1.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
	}
}
