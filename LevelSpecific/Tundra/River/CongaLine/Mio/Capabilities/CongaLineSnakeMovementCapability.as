/**
 * The main player movement during the Conga Line.
 * Simply moves us forward, and rotates on input.
 * It also checks collision with the conga line after every move.
 */
class UCongaLineSnakeMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UCongaLinePlayerComponent CongaComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CongaComp = UCongaLinePlayerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CongaLine::GetManager().bIsSnake)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CongaLine::GetManager().bIsSnake)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			/**
			 * Gravity might not be necessary since the floor is entirely flat, but this just makes sure the player is grounded.
			 */
			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();

			const FQuat Rotation = GetRotation(DeltaTime);
			MoveData.SetRotation(Rotation);

			const FVector Forward = Rotation.ForwardVector;
			const float Speed = CongaComp.GetSpeed(Forward, DeltaTime);

			const FVector Velocity = Forward * Speed;
			MoveData.AddVelocity(Velocity);

			/**
			* Check if we are colliding with the conga line
			* The implementation is dirt simple and very unoptimized
			*/
			CongaComp.CheckCollisionWithCongaLine();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		/**
		 * Requesting SnowMonkeyConga makes sure that the animation feature with that tag is used
		 * @see ULocomotionFeatureSnowMonkeyConga
		 */

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, n"CongaMovement");
	}

	FQuat GetRotation(float DeltaTime) const
	{
		if(MoveComp.MovementInput.IsNearlyZero())
			return Owner.ActorQuat;

		FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, MoveComp.MovementInput);

		return Math::QInterpConstantTo(Owner.ActorQuat, TargetRotation, DeltaTime, CongaComp.Settings.InterpTowardsDirectionTurnSpeed + CongaLine::TurnRateIncreasePerMonkey * CongaComp.CurrentDancerCount());
	}
};