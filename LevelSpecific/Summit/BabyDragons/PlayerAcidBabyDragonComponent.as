
enum EAcidBabyDragonAnimationState
{
	Idle,
	Gliding,
	AirBoostDoubleJump,
};

struct FBabyDragonAirDiveLaunchParams
{
	bool bHasTarget = false;
	USceneComponent TargetRelativeTo;
	FVector TargetLocation;
};

class UPlayerAcidBabyDragonComponent : UPlayerBabyDragonComponent
{
	UPROPERTY()
	TSubclassOf<UCrosshairWidget> AcidSprayCrosshair;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> AcidSprayCameraShake;

	UPROPERTY()
	TSubclassOf<AAcidProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<AAcidPuddle> PuddleClass;

	UPROPERTY()
	UForceFeedbackEffect HoverFF;

	bool bIsFiringAcid = false;
	bool bInAirCurrent = false;
	bool bIsGliding = false;
	float LastAirCurrentTime = -100.0;

	TInstigated<EAcidBabyDragonAnimationState> AnimationState;
	default AnimationState.DefaultValue = EAcidBabyDragonAnimationState::Idle;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (BabyDragon == nullptr)
			return;
		if(BabyDragon.Player != nullptr && BabyDragon.Mesh != nullptr && bIsGliding)
		{
			float Velocity = BabyDragon.Player.GetActorVelocity().Size();
			
			BabyDragon.Mesh.SetScalarParameterValueOnMaterials(n"wingFlappingStrength", Math::Clamp((Velocity / 80) * BabyDragon.WingFlappingStrength, 0, 15));
		}
		else
		{
			BabyDragon.Mesh.SetScalarParameterValueOnMaterials(n"wingFlappingStrength", 0);
		}
	}
};