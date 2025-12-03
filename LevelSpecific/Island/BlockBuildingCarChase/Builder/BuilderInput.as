
class UBuilderInput : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Example");
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UBuilderComponent BuilderComponent;
	AHazePlayerCharacter Player;
	float BlockMovementMultiplier = 1;
	float InputCooldown = 0.15;
	float InputCooldownTimer = 0;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BuilderComponent = UBuilderComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BuilderComponent.CurrentBuildingBlock == nullptr)
			return;

		//Rotate Right
		if(WasActionStarted(ActionNames::WeaponFire))
		{
			BuilderComponent.CurrentBuildingBlock.AddActorWorldRotation(FRotator(0, 90,0));
		}
		//Rotate Left
		if(WasActionStarted(ActionNames::WeaponAim))
		{
			BuilderComponent.CurrentBuildingBlock.AddActorWorldRotation(FRotator(0, -90,0));
		}
		//Place Building block
		if(WasActionStarted(ActionNames::MovementJump))
		{
			BuilderComponent.PlaceCurrentBuildingBlock();
		}



		if(InputCooldownTimer > 0)
		{
			InputCooldownTimer -= DeltaTime;
				return;	
		}
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		//Down
		if(RawStick.X < 0)
		{
			BuilderComponent.CurrentBuildingBlock.AddActorWorldOffset(FVector(0, 2000 * BlockMovementMultiplier,0));
			InputCooldownTimer = InputCooldown;
		}
		//Up
		if(RawStick.X > 0)
		{
			BuilderComponent.CurrentBuildingBlock.AddActorWorldOffset(FVector(0,-2000 * BlockMovementMultiplier,0));
			InputCooldownTimer = InputCooldown;
		}
		//Left
		if(RawStick.Y < 0)
		{	
			BuilderComponent.CurrentBuildingBlock.AddActorWorldOffset(FVector(-2000 * BlockMovementMultiplier,0,0));
			InputCooldownTimer = InputCooldown;
		}
		//Right
		if(RawStick.Y > 0)
		{
			BuilderComponent.CurrentBuildingBlock.AddActorWorldOffset(FVector(2000 * BlockMovementMultiplier,0,0));
			InputCooldownTimer = InputCooldown;
		}
	}
}