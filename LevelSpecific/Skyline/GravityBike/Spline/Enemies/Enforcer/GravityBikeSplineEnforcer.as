asset GravityBikeSplineEnforcerSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGravityBikeSplineEnforcerAimCapability);
	Capabilities.Add(UGravityBikeSplineEnforcerFireCapability);
	Capabilities.Add(UGravityBikeSplineEnforcerDeathCapability);

	Capabilities.Add(UGravityBikeSplineEnforcerGrabbedCapability);
	Capabilities.Add(UGravityBikeSplineEnforcerDroppedCapability);
	Capabilities.Add(UGravityBikeSplineEnforcerThrownCapability);

	Capabilities.Add(UGravityBikeWhipThrowableGrabbedCapability);
	Capabilities.Add(UGravityBikeWhipThrowableThrownCapability);
};

enum EGravityBikeSplineEnforcerState
{
	Idle,
	Grabbed,
	Thrown,
	Dropped,
};

UCLASS(Abstract)
class AGravityBikeSplineEnforcer : AGravityBikeSplineEnemy
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = RightAttach)
	UStaticMeshComponent RifleMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent CapsuleComp;
	default CapsuleComp.GenerateOverlapEvents = false;
	default CapsuleComp.CollisionProfileName = CollisionProfile::EnemyIgnoreCharacters;

	UPROPERTY(DefaultComponent)
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWhipThrowTargetComponent ThrowTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWhipThrowableComponent ThrowableComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineEnforcerSheet);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 75000;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable")
	float Gravity = 2000;

	EGravityBikeSplineEnforcerState State;
	bool bIsShooting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SetActorControlSide(GravityBikeWhip::GetPlayer());
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return CapsuleComp.WorldLocation;
	}

	UPrimitiveComponent GetCollider() const override
	{
		return CapsuleComp;
	}
};