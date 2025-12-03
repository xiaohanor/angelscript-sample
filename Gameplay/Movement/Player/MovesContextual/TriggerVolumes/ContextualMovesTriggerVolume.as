
event void FContextualMovesTriggerEvent(AHazePlayerCharacter Player);

/**
 * Trigger volume that stores arrays of contextual move points to enable/disable when player enters/leaves
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD Datalayers", ComponentWrapperClass)
class AContextualMovesTriggerVolume : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.07, 0.70, 0.10));
	default BrushComponent.LineThickness = 4.0;	
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default PrimaryActorTick.bStartWithTickEnabled = false;

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

#if EDITOR

	UPROPERTY(DefaultComponent)
	UArrowComponent WorldUpArrow;
	default WorldUpArrow.ArrowColor = FLinearColor::Green;
	default WorldUpArrow.RelativeRotation = ActorUpVector.Rotation();
	default WorldUpArrow.RelativeScale3D = FVector::OneVector * 5;
	default WorldUpArrow.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent)
	UContextualMovesVolumeVisualizerComponent VisualizerComp;

#endif

	//Actors to enable when player enters volume
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Trigger Settings")
	TArray<AHazeActor> ContextMoveActorsToEnable;

	//Actors to disable when player enters volume
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Trigger Settings")
	TArray<AHazeActor> ContextMoveActorsToDisable;

	/* 
	 * Should all Contextual targetables in array start as disabled?
	 * Will disable them with Volume / Custom instigator as instigator
	 * This will override any StartDisabled settings on the point instance on BeginPlay
	 */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Trigger Settings")
	bool bDisableActorsOnStart = true;

	//If you want to supply a custom instigator to enable/disable with
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Trigger Settings", meta = (InlineEditConditionToggle))
	bool bOverrideInstigator;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Trigger Settings", meta = (EditCondition = "bOverrideInstigator"))
	FName CustomInstigator;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trigger Settings")
	bool bTriggerForMio = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trigger Settings")
	bool bTriggerForZoe = true;

	//Should Volume triggers ignore networking and only trigger locally
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trigger Settings", AdvancedDisplay)
	bool bTriggerLocally = false;

	//Should The trigger check player worldup / enable when it matches trigger upvector
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trigger Settings", AdvancedDisplay)
	bool bValidateWorldUp = false;

	//How much can player world up deviate from Trigger Upvector for valid activation
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Trigger Settings", AdvancedDisplay, meta = (EditCondition = "bValidateWorldUp", ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0"))
	float WorldUpDegreeMargin = 15;

	UPROPERTY(Category = "Trigger Events")
	FContextualMovesTriggerEvent OnPlayerEnter;

	UPROPERTY(Category = "Trigger Events")
	FContextualMovesTriggerEvent OnPlayerLeave;

	UPROPERTY(Category = "Trigger Events")
	FContextualMovesTriggerEvent OnActivatedForPlayer;

	UPROPERTY(Category = "Trigger Events")
	FContextualMovesTriggerEvent OnDeactivatedForPlayer;

	private TPerPlayer<FContextualMovesTriggerPerPlayerData> PerPlayerData;

	private int CurrentPlayerCount = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR
	
		WorldUpArrow.bVisible = bValidateWorldUp;

#endif

		UContextualMovesTargetableComponent TargetableComp;
		TArray<AHazeActor> ActorsToRemove;

		for(auto ContextActor : ContextMoveActorsToEnable)
		{
			if(ContextActor == nullptr)
				continue;

			TargetableComp = ContextActor.GetComponentByClass(UContextualMovesTargetableComponent);

			if(TargetableComp == nullptr)
			{
				ActorsToRemove.Add(ContextActor);
			}
		}

		if(ActorsToRemove.Num() > 0)
		{
			devErrorAlways("Tried to add actors without contextual moves targetable component");

			for(auto ActorToRemove : ActorsToRemove)
			{
				ContextMoveActorsToEnable.RemoveSwap(ActorToRemove);
			}

			ActorsToRemove.Empty();
		}

		for (auto ContextActor : ContextMoveActorsToDisable)
		{
			if(ContextActor == nullptr)
				continue;

			TargetableComp = ContextActor.GetComponentByClass(UContextualMovesTargetableComponent);
			
			if(TargetableComp == nullptr)
			{
				ActorsToRemove.Add(ContextActor);
			}
		}

		if(ActorsToRemove.Num() > 0)
		{
			devErrorAlways("Tried to add actors without contextual moves targetable component");

			for(auto ActorToRemove : ActorsToRemove)
			{
				ContextMoveActorsToDisable.RemoveSwap(ActorToRemove);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bDisableActorsOnStart)
		{
			for (auto SelectedActor : ContextMoveActorsToEnable)
			{
				TArray<UActorComponent> TargetableComps;
				UContextualMovesTargetableComponent ContextTargetableComp;

				TargetableComps = (SelectedActor.GetComponentsByClass(UContextualMovesTargetableComponent));

				if(TargetableComps.Num() == 0)
					continue;

				for (auto SelectedComp : TargetableComps)
				{
					ContextTargetableComp = Cast<UContextualMovesTargetableComponent>(SelectedComp);

					if(ContextTargetableComp == nullptr)
						return;
					
					//If Start disabled was set on point then override the disable with this or our custom instigator
					if(ContextTargetableComp.bStartDisabled)
						ContextTargetableComp.EnableAfterStartDisabled();

					if(bOverrideInstigator)
						ContextTargetableComp.Disable(CustomInstigator);
					else
						ContextTargetableComp.Disable(this);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::GetPlayers())
		{
			if(PerPlayerData[Player].bIsPlayerInside)
			{
				if(!PerPlayerData[Player].bHasActivatedForPlayer)
				{
					if(VerifyPlayerWorldUp(Player))
					{
						if(Player.HasControl() && !bTriggerLocally)
							CrumbActivateLinkedActorsForPlayer(Player);
						else
							ActivateLinkedActorsForPlayer(Player);
					}
				}
				else
				{
					if(!VerifyPlayerWorldUp(Player))
					{
						if(Player.HasControl() && !bTriggerLocally)	
							CrumbDeactivateLinkedActorsForPlayer(Player);
						else
							DeactivateLinkedActorsForPlayer(Player);
					}
				}
			}
		}
	}

	UFUNCTION(Category = "Contextual Moves Trigger")
	void EnableContextualMovesTrigger(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			PlayerData.DisableInstigators.Remove(Instigator);
		}

		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Contextual Moves Trigger")
	void DisableContextualMovesTrigger(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			PlayerData.DisableInstigators.AddUnique(Instigator);
		}
	
		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Contextual Moves Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);

		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Contextual Moves Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);

		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Contextual Moves Trigger")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
		{
			if (!bTriggerForMio)
				return false;
		}
		else
		{
			if (!bTriggerForZoe)
				return false;
		}

		const auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.DisableInstigators.Num() != 0)
			return false;

		return true;
	}
	
	//Manually update which players are inside, we may have missed an overlap event due to disabling or during streaming
	private void UpdateAlreadyInsidePlayers()
	{
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl() && !bTriggerLocally)
				continue;

			auto& PlayerData = PerPlayerData[Player];
			bool bIsInside = false;
			if (IsEnabledForPlayer(Player))
			{
				if(Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			if (PlayerData.bIsPlayerInside && !bIsInside)
			{
				if (!bTriggerLocally)
					CrumbPlayerLeave(Player);
				else
					TriggerOnPlayerLeave(Player);
				
				PlayerData.bIsPlayerInside = false;
			}
			else if(!PlayerData.bIsPlayerInside && bIsInside)
			{
				if(!bTriggerLocally)
					CrumbPlayerEnter(Player);
				else
					TriggerOnPlayerEnter(Player);
				
				PlayerData.bIsPlayerInside = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	private void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;
		if (!IsEnabledForPlayer(Player))
			return;

		auto& PlayerData = PerPlayerData[Player];
		if (!PlayerData.bIsPlayerInside)
		{
			PlayerData.bIsPlayerInside = true;
			if(!bTriggerLocally)
				CrumbPlayerEnter(Player);
			else
				TriggerOnPlayerEnter(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	private void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;
		if (!IsEnabledForPlayer(Player))
			return;

		auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.bIsPlayerInside)
		{
			PlayerData.bIsPlayerInside = false;
			if (!bTriggerLocally)
				CrumbPlayerLeave(Player);
			else
				TriggerOnPlayerLeave(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerEnter(AHazePlayerCharacter Player)
	{
		TriggerOnPlayerEnter(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerLeave(AHazePlayerCharacter Player)
	{
		TriggerOnPlayerLeave(Player);
	}

	private void TriggerOnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(bValidateWorldUp)
		{
			CurrentPlayerCount++;

			SetActorTickEnabled(true);
		}
		else
			ActivateLinkedActorsForPlayer(Player);

		OnPlayerEnter.Broadcast(Player);
	}

	private void TriggerOnPlayerLeave(AHazePlayerCharacter Player)
	{
		if(bValidateWorldUp)
		{
			CurrentPlayerCount--;

			if(CurrentPlayerCount == 0)
				SetActorTickEnabled(false);
		}

		if(!bValidateWorldUp || (bValidateWorldUp && PerPlayerData[Player].bHasActivatedForPlayer))
			DeactivateLinkedActorsForPlayer(Player);

		OnPlayerLeave.Broadcast(Player);
	}

	//Perform enable/disable for player on trigger enter or world up aligned
	private void ActivateLinkedActorsForPlayer(AHazePlayerCharacter Player)
	{
		TArray<UActorComponent> TargetableComps;
		UContextualMovesTargetableComponent ContextTargetableComp;

		for (auto EnableActor : ContextMoveActorsToEnable)
		{
			if(EnableActor == nullptr)
				continue;

			TargetableComps = (EnableActor.GetComponentsByClass(UContextualMovesTargetableComponent));

			if(TargetableComps.Num() == 0)
				continue;
			
			for (auto SelectedComp : TargetableComps)
			{
				ContextTargetableComp = Cast<UContextualMovesTargetableComponent>(SelectedComp);

				if(ContextTargetableComp == nullptr || !Player.IsSelectedBy(ContextTargetableComp.UsableByPlayers))
					continue;

				if(bOverrideInstigator)
					ContextTargetableComp.EnableForPlayer(Player, CustomInstigator);
				else
					ContextTargetableComp.EnableForPlayer(Player, this);
			}
		}	

		for (auto DisableActor : ContextMoveActorsToDisable)
		{
			if(DisableActor == nullptr)
				continue;

			TargetableComps = (DisableActor.GetComponentsByClass(UContextualMovesTargetableComponent));

			if(TargetableComps.Num() == 0)
				continue;

			for (auto SelectedComp : TargetableComps)
			{
				ContextTargetableComp = Cast<UContextualMovesTargetableComponent>(SelectedComp);
				
				if(ContextTargetableComp == nullptr || !Player.IsSelectedBy(ContextTargetableComp.UsableByPlayers))
					continue;

				if(bOverrideInstigator)
					ContextTargetableComp.DisableForPlayer(Player, CustomInstigator);
				else
					ContextTargetableComp.DisableForPlayer(Player, this);
			}
		}

		PerPlayerData[Player].bHasActivatedForPlayer = true;

		OnActivatedForPlayer.Broadcast(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateLinkedActorsForPlayer(AHazePlayerCharacter Player)
	{
		ActivateLinkedActorsForPlayer(Player);
	}

	//Perform Enable/Disable for player on trigger exit or lost worldup alignment 
	private void DeactivateLinkedActorsForPlayer(AHazePlayerCharacter Player)
	{
		TArray<UActorComponent> TargetableComps;
		UContextualMovesTargetableComponent ContextTargetableComp;

		for (auto EnableActor : ContextMoveActorsToEnable)
		{
			if(EnableActor == nullptr)
				continue;

			TargetableComps = (EnableActor.GetComponentsByClass(UContextualMovesTargetableComponent));

			if(TargetableComps.Num() == 0)
				continue;

			for (auto ActorComp : TargetableComps)
			{
				ContextTargetableComp = Cast<UContextualMovesTargetableComponent>(ActorComp);
				
				if(ContextTargetableComp == nullptr || !Player.IsSelectedBy(ContextTargetableComp.UsableByPlayers))
					continue;

				if(bOverrideInstigator)
					ContextTargetableComp.DisableForPlayer(Player, CustomInstigator);
				else
					ContextTargetableComp.DisableForPlayer(Player, this);
			}
		}	

		for (auto DisableActor : ContextMoveActorsToDisable)
		{
			if(DisableActor == nullptr)
				continue;

			TargetableComps = (DisableActor.GetComponentsByClass(UContextualMovesTargetableComponent));

			if(TargetableComps.Num() == 0)
				continue;

			for (auto ActorComp : TargetableComps)
			{
				ContextTargetableComp = Cast<UContextualMovesTargetableComponent>(ActorComp);
				
				if(ContextTargetableComp == nullptr || !Player.IsSelectedBy(ContextTargetableComp.UsableByPlayers))
					continue;

				if(bOverrideInstigator)
					ContextTargetableComp.EnableForPlayer(Player, CustomInstigator);
				else
					ContextTargetableComp.EnableForPlayer(Player, this);
			}
		}

		PerPlayerData[Player].bHasActivatedForPlayer = false;

		OnDeactivatedForPlayer.Broadcast(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivateLinkedActorsForPlayer(AHazePlayerCharacter Player)
	{
		DeactivateLinkedActorsForPlayer(Player);
	}

	private bool VerifyPlayerWorldUp(AHazePlayerCharacter Player)
	{
		if (ActorUpVector.DotProduct(Player.MovementWorldUp) < 0.0)
			return false;
		
		float Angle = ActorUpVector.GetAngleDegreesTo(Player.MovementWorldUp);
		if (Angle > WorldUpDegreeMargin)
			return false;

		return true;
	}
}

//Dummy comp for visualizer
class UContextualMovesVolumeVisualizerComponent : UActorComponent{};

struct FContextualMovesTriggerPerPlayerData
{
	bool bIsPlayerInside = false;
	bool bHasActivatedForPlayer = false;
	TArray<FInstigator> DisableInstigators;
}