/**
 * AI movement component
 */
class UBasicAICharacterMovementComponent : UHazeMovementComponent
{
	AHazeCharacter Character;

	default bConstrainRotationToHorizontalPlane = true;

	protected FName LastPerformedMove = NAME_None;	

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Character = Cast<AHazeCharacter>(Owner);
		SetupShapeComponent(Character.CapsuleComponent);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Reset();
	}

	UFUNCTION(Category = "Movement")
	void ApplyMoveAndRequestLocomotion(UBaseMovementData Movement, FName AnimationTag)    
	{
		LastPerformedMove = AnimationTag;
		ApplyMove(Movement);		
		if(Character.Mesh.CanRequestLocomotion())
		{
			// FLinearColor DebugColor = Owner == Game::Mio ? FLinearColor::Yellow : FLinearColor::Green;
			// PrintToScreen("Requesting Tag: " + AnimationTag, Color = DebugColor);
			Character.Mesh.RequestLocomotion(AnimationTag, this);
		}	
	}

	float GetCollisionCapsuleRadius() const
	{
		return GetCollisionShape().Shape.CapsuleRadius;
	}

	float GetCollisionCapsuleHalfHeight() const
	{
		return GetCollisionShape().Shape.CapsuleHalfHeight;
	}

	FRotator GetRotationTowardsDirection(FVector Direction, float RotationDuration, float DeltaTime, bool bOverride = false)
	{
		if (!bOverride)
	 		AccRotation.Value = Owner.ActorRotation;  // In case something else has rotated us
		AccRotation.AccelerateTo(Direction.Rotation(), RotationDuration, DeltaTime);
		return AccRotation.Value;
	}

	FRotator GetStoppedRotation(float Damping, float DeltaTime, bool bOverride = false)
	{	
		if (!bOverride)	
			AccRotation.Value = Owner.ActorRotation;  // In case something else has rotated us
		AccRotation.Velocity.Yaw = Math::Clamp(AccRotation.Velocity.Yaw, -45.0, 45.0);
		AccRotation.Velocity -= AccRotation.Velocity * Damping * DeltaTime;
		AccRotation.Value += AccRotation.Velocity * DeltaTime;
		return AccRotation.Value;
	}

	void RotateTowardsDirection(FVector Direction, float RotationDuration, float DeltaTime, UBaseMovementData Movement, bool bOverride = false)
	{
		Movement.SetRotation(GetRotationTowardsDirection(Direction, RotationDuration, DeltaTime, bOverride));
	}

	void StopRotating(float Damping, float DeltaTime, UBaseMovementData Movement, bool bOverride = false)
	{
		Movement.SetRotation(GetStoppedRotation(Damping, DeltaTime));
	}
}
