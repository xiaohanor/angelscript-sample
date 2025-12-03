
/** 
 * Uses faux phys to swing a mesh. 
 * 
 * forces can be applied to this actor only or via
 * the global Environment::Apply*Force() functions
 * 
 * This actor registers to the Environment singleton on beginplay
 * 
 * @TODO: move the shockwave function to Faux instead
*/

event void FForceHitEvent(FVector Force);

class AEnvironmentSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, Category = "Swingable Mesh")
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Category = "Swingable Mesh")
	UFauxPhysicsFreeRotateComponent FauxFreeRotate;
	default FauxFreeRotate.Friction = 0.7;
	default FauxFreeRotate.SpringStrength = 0.3;

	UPROPERTY(DefaultComponent,Category = "Swingable Mesh", Attach = FauxFreeRotate)
	UFauxPhysicsAxisRotateComponent FauxAxisRotate;
	default FauxAxisRotate.Friction = 0.7;
	default FauxAxisRotate.SpringStrength = 0.3;

	UPROPERTY(DefaultComponent,Category = "Swingable Mesh", Attach = FauxAxisRotate)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent,Category = "Swingable Mesh", Attach = Mesh)
	UFauxPhysicsWeightComponent FauxWeight;
	default FauxWeight.MassScale = 0.25;

	// will trigger when the swing get hit by a force
	UPROPERTY(Category = "Swingable Mesh")
	FForceHitEvent OnHitByShockwaveForce;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent HazeCapabilityComponent;

	UPROPERTY(EditAnywhere, Category = "Swingable Mesh")
	bool bDoPlayerCollision = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Environment::GetForceEmitter().RegisterSwing(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Environment::GetForceEmitter().UnregisterSwing(this);
	}

	/** Will apply a force to this actor if its within the radial radius 
	  	(You can apply this on tick) */
	UFUNCTION(BlueprintCallable, Category = "Swingable Mesh")
	void ApplyShockwaveForce(const FEnvironmentShockwaveForceData& ForceData)
	{
		FVector Force = ForceData.CalculateForceForTarget(Mesh.GetWorldLocation());

		if(Force.IsZero())
			return;

		OnHitByShockwaveForce.Broadcast(Force);

		FauxPhysics::ApplyFauxForceToActorAt(this, ForceData.Epicenter, Force);
	}

	/** Will apply an Impulse this actor if its within the Radial radius
		(Use this as a one-shot) */
	UFUNCTION(BlueprintCallable, Category = "Swingable Mesh")
	void ApplyShockwaveImpulse(const FEnvironmentShockwaveForceData& ForceData)
	{
		FVector Impulse = ForceData.CalculateForceForTarget(Mesh.GetWorldLocation());

		if(Impulse.IsZero())
			return;

		OnHitByShockwaveForce.Broadcast(Impulse);

		FauxPhysics::ApplyFauxImpulseToActorAt(this, ForceData.Epicenter, Impulse);
	}

	UFUNCTION(BlueprintCallable)
	void HandlePlayerCollision(UPrimitiveComponent CollisionComp, AHazePlayerCharacter Player)
	{
		if(bDoPlayerCollision == false)
			return;

		UPrimitiveComponent CollidingSwing = CollisionComp != nullptr ? CollisionComp : Mesh;

		FVector SwingLocation = CollidingSwing.GetBoundsOrigin();
		float SwingBounds = CollidingSwing.GetBoundsRadius() * 0.5;

		FVector PlayerLocation = Player.CapsuleComponent.WorldLocation;
		FVector Capsule_Top = PlayerLocation + Player.CapsuleComponent.WorldRotation.UpVector*Player.CapsuleComponent.GetScaledCapsuleHalfHeight_WithoutHemisphere();
		FVector Capsule_Bottom = PlayerLocation - Player.CapsuleComponent.WorldRotation.UpVector*Player.CapsuleComponent.GetScaledCapsuleHalfHeight_WithoutHemisphere();
		float CapsuleRadius = Player.CapsuleComponent.GetScaledCapsuleRadius();

		FVector ClosestPointOnCapsuleLine = Math::ClosestPointOnLine(
			Capsule_Top,
			Capsule_Bottom,
			SwingLocation
		);

		const float CombinedRadius = SwingBounds + CapsuleRadius;
		const FVector DeltaBetween = SwingLocation - ClosestPointOnCapsuleLine;
		float DistanceBetween = DeltaBetween.Size() - CombinedRadius;

		// Debug::DrawDebugCapsule(PlayerLocation,
		// Player.CapsuleComponent.GetScaledCapsuleHalfHeight(),
		// Player.CapsuleComponent.GetScaledCapsuleRadius(),
		// Player.CapsuleComponent.GetWorldRotation(),
		// FLinearColor::Blue,
		// 2.0,0
		// );
		// Debug::DrawDebugSphere(SwingLocation, SwingBounds, 12, FLinearColor::Yellow, 2.0);

		if(DistanceBetween > 0)
			return;

		const float PositiveDistanceBetween = Math::Abs(DistanceBetween);
		const float ForceScaler = PositiveDistanceBetween * 20.0;
		const FVector DepenetrationImpulse = DeltaBetween.GetSafeNormal() * ForceScaler;

		// this will zero out the velocity. We want the thing to come to a stop when it hits the player, not bounce off.
		// FauxFreeRotate.ResetPhysics();

		// ApplyFauxImpulseToActorAt(this, ClosestPointOnCapsuleLine, DepenetrationImpulse);
		FauxPhysics::ApplyFauxForceToActorAt(this, ClosestPointOnCapsuleLine, DepenetrationImpulse);

		// Debug::DrawDebugSphere(Capulse_Top, SwingBounds, 12, FLinearColor::Yellow, 2.0);
		// Debug::DrawDebugSphere(Capulse_Bottom, SwingBounds, 12, FLinearColor::Yellow, 2.0);

	}

}