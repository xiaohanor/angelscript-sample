
UCLASS(Abstract)
class AAISanctuarySnake : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuarySnakeTailCapability");

	UPROPERTY(DefaultComponent)
	ULightProjectileTargetComponent LightProjectileTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBeamTargetComponent LightBeamTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBeamResponseComponent LightBeamResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkProjectileTargetComponent DarkProjectileTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UBasicAIMeleeWeaponComponent MeleeComp;

	UPROPERTY()
	USanctuarySnakeSettings DefaultSettings;

	UPROPERTY(DefaultComponent)
	USanctuarySnakeComponent SanctuarySnakeComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(DefaultSettings);

		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}
}
