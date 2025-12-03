UCLASS(HideCategories = "InternalHiddenObjects")
class AHoverboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 50.0;
	default Collision.GenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent LeanPivot;

	UPROPERTY(DefaultComponent, Attach = LeanPivot)
	USceneComponent PlayerAttach;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent CameraFocusTarget;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USpringArmCamera Camera;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"HoverboardMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	FVector Gravity = FVector::UpVector * -1000.0;
	FVector2D Lean;
	float Drag = 1.0;

	bool bActive = false;
	bool bBoost = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Setup the resolver
		{	
			UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Override the gravity settings
		{
			UMovementGravitySettings::SetGravityScale(this, 6, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LeanPivot.SetRelativeRotation(FRotator(Math::Clamp(-Lean.Y * 30.0, -10.0, 30.0), Lean.X * 30.0, Lean.X * 30.0));
	}
}