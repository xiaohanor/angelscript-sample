
class UIslandFloatotronDamageReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandRedBlueImpactCounterResponseComponent ResponseComp;	
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceFieldComp;
	UIslandFloatotronSettings FloatotronSettings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);	
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		ResponseComp = UIslandRedBlueImpactCounterResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		FloatotronSettings = UIslandFloatotronSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!ForceFieldComp.IsDepleted())
			return;

		HealthComp.TakeDamage(FloatotronSettings.DefaultDamage * Data.ImpactDamageMultiplier, EDamageType::Projectile, Data.Player);
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
		if (ActiveDuration > FloatotronSettings.HurtReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::Medium, this, FloatotronSettings.HurtReactionDuration);

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
			float Pitch = HackPitch.SpringTo(60.0, 500.0, 0.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
		else
		{
			float Pitch = HackPitch.AccelerateTo(0.0, 1.0, DeltaTime);
			Mesh.SetRelativeRotation(FRotator(Pitch, MeshRot.Yaw, MeshRot.Roll));
		}
	}
}

