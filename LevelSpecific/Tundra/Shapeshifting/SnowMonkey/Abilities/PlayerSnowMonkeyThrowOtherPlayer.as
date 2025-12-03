
UCLASS(Abstract)
class UTundraPlayerSnowMonkeyThrowOtherInteration : UTargetableComponent
{
	default TargetableCategory = n"Interaction";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY()
	bool bShowAsExclusiveToPlayer = false;

	UPROPERTY()
	float ActivationRange = 200;	

	bool CheckTargetable(FTargetableQuery& Query) const override
	{	
		if(Query.Player.ActorLocation.DistSquared(WorldLocation) > Math::Square(ActivationRange))
			return false;

		auto MyShapeComp = UTundraPlayerShapeshiftingComponent::Get(Query.Player);
		if(MyShapeComp == nullptr)
			return false;
		
		if(MyShapeComp.CurrentShapeType != ETundraShapeshiftShape::Small)
			return false;

		auto GorillaComp = UTundraPlayerSnowMonkeyComponent::Get(Query.Player.OtherPlayer);
		if(GorillaComp == nullptr)
			return false;
		
		if(!GorillaComp.bIsInThrowMode)
			return false;

		Query.Result.Score = 1;
		return true;
	}
}


class UTundraPlayerSnowMonkeyThrowOtherPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyThrow);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerSnowMonkeyThrowOtherInteration Interaction;
	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	UTundraPlayerSnowMonkeyComponent GorillaComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerSnowMonkeySettings GorillaSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Interaction = UTundraPlayerSnowMonkeyThrowOtherInteration::Get(Player);
		Interaction.AttachToComponent(Player.Mesh, n"RightHand");

		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		GorillaComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings ::GetSettings(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if (!WasActionStarted(ActionNames::Interaction))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;
		
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (WasActionStarted(ActionNames::Interaction))
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;


		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		GorillaComp.bIsInThrowMode = true;	

		// Camera
		if(GorillaComp.ThrowOtherPlayerCameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(GorillaComp.ThrowOtherPlayerCameraSettings, 2, this, SubPriority = 70);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		GorillaComp.bIsInThrowMode = false;

		// Camera
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				FRotator WantedRotation = Player.GetActorRotation();
				FVector Input = MoveComp.MovementInput;
				if(!Input.IsNearlyZero(0.1))
				{
					WantedRotation = Math::RInterpTo(WantedRotation, FRotator::MakeFromZX(MoveComp.WorldUp, Input), DeltaTime, 10);
				}
				Movement.SetRotation(WantedRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ThrowOtherPlayer");
		}
	}
};