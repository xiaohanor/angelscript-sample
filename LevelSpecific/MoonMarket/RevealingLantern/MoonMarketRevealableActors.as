class AMoonMarketRevealableActors : AHazeActor
{
	UPROPERTY(DefaultComponent)
	private UHazeListedActorComponent ListedActorComp;

	private TArray<UMoonMarketRevealableComponent> Colliders;
	//private TArray<AActor> ColliderActors;

	//TPerPlayer<bool> CanCollide;
	TPerPlayer<UMoonMarketShapeshiftComponent> PlayerShapeshiftComps;
	TPerPlayer<UHazeMovementComponent> PlayerMoveComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerMoveComps[Game::Zoe] = UHazeMovementComponent::Get(Game::Zoe);
		PlayerMoveComps[Game::Mio] = UHazeMovementComponent::Get(Game::Mio);

		PlayerShapeshiftComps[Game::Zoe] = UMoonMarketShapeshiftComponent::GetOrCreate(Game::Zoe);
		PlayerShapeshiftComps[Game::Mio] = UMoonMarketShapeshiftComponent::GetOrCreate(Game::Mio);
		// CanCollide[Game::GetMio()] = true;
		// CanCollide[Game::GetZoe()] = true;
	}

	void AddRevealableCollider(UMoonMarketRevealableComponent Comp)
	{
		Colliders.Add(Comp);
		//ColliderActors.Add(Comp.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateCollidersTwoColors();
	}

	// void UpdateCollidersOneColor()
	// {
	// 	for(auto Player : Game::GetPlayers())
	// 	{
	// 		bool bCanCollide = CanCollideOneColor(Player);

	// 		if(bCanCollide != CanCollide[Player])
	// 		{
	// 			CanCollide[Player] = bCanCollide;
				
	// 			if(!bCanCollide)
	// 				UHazeMovementComponent::Get(Player).AddMovementIgnoresActors(this, ColliderActors);
	// 			else
	// 				UHazeMovementComponent::Get(Player).RemoveMovementIgnoresActor(this);
	// 		}
	// 	}
	// }

	void UpdateCollidersTwoColors()
	{
		for(auto Collider : Colliders)
		{
			for(auto Player : Game::GetPlayers())
			{
				bool bCanCollide = CanCollideTwoColors(Player, Collider);

				if(bCanCollide != Collider.PlayerCanCollide[Player])
				{
					Collider.PlayerCanCollide[Player] = bCanCollide;

					TArray<UHazeMovementComponent> MoveComps;

					if(PlayerShapeshiftComps[Player].ShapeshiftShape != nullptr)
					{
						PlayerShapeshiftComps[Player].ShapeshiftShape.CurrentShape.GetComponentsByClass(UHazeMovementComponent, MoveComps);
					}
					
					MoveComps.Add(PlayerMoveComps[Player]);
					
					for(auto MoveComp : MoveComps)
					{
						if(!bCanCollide)
							MoveComp.AddMovementIgnoresActor(Collider, Collider.Owner);
						else
							MoveComp.RemoveMovementIgnoresActor(Collider);
					}
				}
			}
		}
	}

	// bool CanCollideOneColor(AHazePlayerCharacter Player) const
	// {
	// 	for(auto Lantern : TListedActors<AMoonMarketRevealingLantern>().Array)
	// 	{
	// 		if(Lantern.HoldingPlayer == Player)
	// 			return true;

	// 		if(Player.ActorLocation.Distance(Lantern.ActorLocation) < Lantern.RevealRadius)
	// 			return true;
	// 	}

	// 	return false;
	// }

	bool CanCollideTwoColors(AHazePlayerCharacter Player, UMoonMarketRevealableComponent Collider) const
	{
		for(auto Lantern : TListedActors<AMoonMarketRevealingLantern>().Array)
		{
			if(Collider.PlatformType != EMoonMarketRevealableColor::Neutral)
				if(Collider.PlatformType != Lantern.PlatformType)
					continue;

			if(Collider.CurrentOpacity < 0.5)
				return false;

			if(Collider.PlatformType == EMoonMarketRevealableColor::Neutral)
				return true;

			if(Lantern.InteractingPlayer == Player)
				return true;

			if(Player.ActorLocation.Distance(Lantern.ActorLocation) < Lantern.CurrentRevealRadius.Value)
				return true;
		}

		return false;
	}
};