UCLASS(Abstract)
class AAICoastWaterJet : ABasicAICharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapsuleComponent.CapsuleRadius = 200;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	default DisableComp.AutoDisableRange = 200000.0;

	default CapabilityComp.DefaultCapabilities.Add(n"CoastWaterJetCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFlyingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastWaterJetMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastWaterJetDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");
	
	UPROPERTY(DefaultComponent)
	UCoastWaterJetComponent WaterJetComp;

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);

		// Hide any water hose until we've fixed nice physics
		UEnvironmentCableComponent Hose = UEnvironmentCableComponent::Get(this);
		if (Hose != nullptr)
			Hose.AddComponentVisualsBlocker(this);
	}
}

class UCoastWaterJetWeaponMuzzleComponent : USceneComponent
{
}

class UCoastWaterJetGrenadeWeaponComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<ACoastWaterJetGrenade> GrenadeClass;
}