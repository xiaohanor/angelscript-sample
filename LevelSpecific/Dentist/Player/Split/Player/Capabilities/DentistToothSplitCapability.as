/**
 * Split the tooth into two halves
 * The left half is the player
 * The right half is a separate AI controlled actor
 */
class UDentistToothSplitCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 10;

	UDentistToothPlayerComponent ToothComp;
	UDentistToothSplitComponent SplitComp;
	
	int SpawnedSplitTeeth = 0;
	UStaticMesh DefaultToothMesh;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ToothComp = UDentistToothPlayerComponent::Get(Player);
		SplitComp = UDentistToothSplitComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplitComp.bShouldSplit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplitComp.bShouldSplit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitComp.bIsSplit = true;
		
		FDentistToothSplitEventHandlerOnSplitEventData EventData;
		EventData.SplitTransform = Player.CapsuleComponent.WorldTransform;
		UDentistToothEventHandler::Trigger_OnSplit(Player, EventData);

		SetupSplitToothAI(SplitComp.SplitToothAIClass[Player]);

		const FVector VerticalImpulse = FVector(0, 0, Dentist::SplitTooth::VerticalImpulse);
		const float HorizontalImpulse = Dentist::SplitTooth::HorizontalImpulse;

		SplitComp.GetPlayerSplitTooth().ResetMovement();
		SplitComp.GetSplitToothAI().ResetMovement();

		SplitComp.GetPlayerSplitTooth().CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);
		SplitComp.GetSplitToothAI().CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);

		auto SplitToothTarget = ADentistSplitToothTarget::Get();
		if(SplitToothTarget != nullptr)
		{
			float Gravity = UHazeMovementComponent::Get(SplitComp.GetPlayerSplitTooth()).GravityForce;
			FVector PlayerImpulse = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, SplitToothTarget.PlayerTargetLocation.WorldLocation, Gravity, Dentist::SplitTooth::TargetLaunchHeight);
			SplitComp.GetPlayerSplitTooth().AddMovementImpulse(PlayerImpulse);

			FVector AIImpulse = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, SplitToothTarget.AITargetLocation.WorldLocation, Gravity, Dentist::SplitTooth::TargetLaunchHeight);
			SplitComp.GetSplitToothAI().AddMovementImpulse(AIImpulse);
		}
		else
		{
			SplitComp.GetPlayerSplitTooth().AddMovementImpulse(VerticalImpulse - (Player.ActorRightVector * HorizontalImpulse));
			SplitComp.GetSplitToothAI().AddMovementImpulse(VerticalImpulse + (Player.ActorRightVector * HorizontalImpulse));
		}

		SplitComp.GetPlayerSplitToothComp().bIsSplit = true;
		SplitComp.GetSplitToothCompAI().bIsSplit = true;

		SplitComp.SplitStartTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplitComp.bIsSplit = false;

		SplitComp.GetPlayerSplitTooth().CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);
		SplitComp.GetSplitToothAI().CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);

		SplitComp.GetPlayerSplitToothComp().bIsSplit = false;
		SplitComp.GetSplitToothCompAI().bIsSplit = false;

		SplitComp.SplitToothAI.AddActorDisable(this);
	}

	void SetupSplitToothAI(TSubclassOf<ADentistSplitToothAI> SplitToothClass) const
	{
		ADentistSplitToothAI Tooth = SplitComp.GetSplitToothAI();

		if(Tooth == nullptr)
		{
			Tooth = SpawnAISplitTooth(SplitToothClass);
			SplitComp.SplitToothAI = Tooth;
		}
		else
		{
			Tooth.RemoveActorDisable(this);
		}

		FVector SpawnLocation = Dentist::SplitTooth::GetSideLocation(Player.ActorTransform, true);
		Tooth.SetActorLocationAndRotation(SpawnLocation, Player.ActorRotation);

		Tooth.State = EDentistSplitToothAIState::Splitting;
	}

	ADentistSplitToothAI SpawnAISplitTooth(TSubclassOf<ADentistSplitToothAI> SplitToothClass) const
	{
		ADentistSplitToothAI SplitTooth = SpawnActor(SplitToothClass, Player.ActorLocation, Player.ActorRotation, bDeferredSpawn = true);
		SplitTooth.MakeNetworked(this, SplitToothClass.Get().Name);
		SplitTooth.SetActorControlSide(Player);
		SplitTooth.OwningPlayer = Player;
		FinishSpawningActor(SplitTooth);
		return SplitTooth;
	}
};