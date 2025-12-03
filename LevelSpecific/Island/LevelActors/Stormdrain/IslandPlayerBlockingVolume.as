class AIslandPlayerBlockingVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPlayerMovementComponent MioMoveComp;
	UPlayerMovementComponent ZoeMoveComp;

	UHoverPerchPlayerComponent MioPerchComp;
	UHoverPerchPlayerComponent ZoePerchComp;

	UPROPERTY(EditInstanceOnly)
	bool bBlockMio = false;
	
	UPROPERTY(EditInstanceOnly)
	bool bBlockZoe = false;

	TPerPlayer<bool> bHasBeenBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
		ZoeMoveComp = UPlayerMovementComponent::Get(Game::Zoe);

		if(!bBlockMio)
			MioMoveComp.AddMovementIgnoresActor(this, this);
		if(!bBlockZoe)
			ZoeMoveComp.AddMovementIgnoresActor(this, this);

		TListedActors<AHoverPerchActor> HoverPerches;
		for(AHoverPerchActor HoverPerch : HoverPerches)
		{
			HoverPerch.MoveComp.AddMovementIgnoresActor(this, this);
		}
	}

	UFUNCTION()
	void BlockForPlayer(AHazePlayerCharacter Player)
	{
		if(Player == Game::Mio)
		{
			MioPerchComp = UHoverPerchPlayerComponent::Get(Game::Mio);
			MioMoveComp.RemoveMovementIgnoresActor(this);
			if(MioPerchComp.PerchActor != nullptr)
				MioPerchComp.PerchActor.MoveComp.RemoveMovementIgnoresActor(this);
		}
		else
		{
			ZoePerchComp = UHoverPerchPlayerComponent::Get(Game::Zoe);
			ZoeMoveComp.RemoveMovementIgnoresActor(this);
			if(ZoePerchComp.PerchActor != nullptr)
				ZoePerchComp.PerchActor.MoveComp.RemoveMovementIgnoresActor(this);
		}

		bHasBeenBlocked[Player] = true;

		if(bHasBeenBlocked[0] && bHasBeenBlocked[1])
		{
			TListedActors<AHoverPerchActor> HoverPerches;
			for(AHoverPerchActor HoverPerch : HoverPerches)
			{
				HoverPerch.MoveComp.RemoveMovementIgnoresActor(this);
			}
		}
	}

	UFUNCTION()
	void UnblockForPlayer(AHazePlayerCharacter Player)
	{
		if(Player == Game::Mio)
		{
			MioPerchComp = UHoverPerchPlayerComponent::Get(Game::Mio);
			MioMoveComp.AddMovementIgnoresActor(this, this);
			if(MioPerchComp.PerchActor != nullptr)
				MioPerchComp.PerchActor.MoveComp.AddMovementIgnoresActor(this, this);
		}
		else
		{
			ZoePerchComp = UHoverPerchPlayerComponent::Get(Game::Zoe);
			ZoeMoveComp.AddMovementIgnoresActor(this, this);
			if(ZoePerchComp.PerchActor != nullptr)
				ZoePerchComp.PerchActor.MoveComp.AddMovementIgnoresActor(this, this);
		}

		bHasBeenBlocked[Player] = false;
	}
};