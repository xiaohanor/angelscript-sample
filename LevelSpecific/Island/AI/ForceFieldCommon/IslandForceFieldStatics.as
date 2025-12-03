namespace IslandForceField
{
	const FName ForceFieldToggleInstigator = n"ForceFieldToggleInstigator";

	// Set up response blocks
	void ResetForceField(EIslandForceFieldType Type, UIslandRedBlueWeaponBaseTargetable TargetableComp, UIslandRedBlueImpactResponseComponent ResponseComp, FInstigator Instigator)
	{	
		if (TargetableComp != nullptr)
			TargetableComp.Enable(Instigator);
		ResponseComp.UnblockImpactForColor(EIslandRedBlueWeaponType::Red, Instigator);
		ResponseComp.UnblockImpactForColor(EIslandRedBlueWeaponType::Blue, Instigator);
		if (Type == EIslandForceFieldType::Blue)
		{
			AHazePlayerCharacter MatchingPlayer = IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Blue);			
			ResponseComp.BlockImpactForPlayer(MatchingPlayer.OtherPlayer, Instigator);
			if (TargetableComp != nullptr)
			{
				if(TargetableComp.IsDisabledForPlayer(MatchingPlayer))
					TargetableComp.EnableForPlayer(MatchingPlayer, ForceFieldToggleInstigator);
				if(!TargetableComp.IsDisabledForPlayer(MatchingPlayer.OtherPlayer))
					TargetableComp.DisableForPlayer(MatchingPlayer.OtherPlayer, ForceFieldToggleInstigator);
			}
		}
		if (Type == EIslandForceFieldType::Red)
		{
			AHazePlayerCharacter MatchingPlayer = IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Red);			
			ResponseComp.BlockImpactForPlayer(MatchingPlayer.OtherPlayer, Instigator);
			if (TargetableComp != nullptr)
			{
				if(TargetableComp.IsDisabledForPlayer(MatchingPlayer))
					TargetableComp.EnableForPlayer(MatchingPlayer, ForceFieldToggleInstigator);
				if(!TargetableComp.IsDisabledForPlayer(MatchingPlayer.OtherPlayer))
					TargetableComp.DisableForPlayer(MatchingPlayer.OtherPlayer, ForceFieldToggleInstigator);
			}
		}
	}

	// Set up response blocks
	void ResetForceFieldStickyGrenade(EIslandForceFieldType Type, UIslandRedBlueWeaponBaseTargetable TargetableComp, UIslandRedBlueStickyGrenadeResponseComponent ResponseComp, FInstigator Instigator)
	{	
		if (TargetableComp != nullptr)
			TargetableComp.Enable(Instigator);
		ResponseComp.UnblockImpactForColor(EIslandRedBlueWeaponType::Red, Instigator);
		ResponseComp.UnblockImpactForColor(EIslandRedBlueWeaponType::Blue, Instigator);
		if (Type == EIslandForceFieldType::Blue)
		{
			AHazePlayerCharacter MatchingPlayer = IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Blue);			
			ResponseComp.BlockImpactForPlayer(MatchingPlayer.OtherPlayer, Instigator);
			if (TargetableComp != nullptr)
			{
				if(TargetableComp.IsDisabledForPlayer(MatchingPlayer))
					TargetableComp.EnableForPlayer(MatchingPlayer, ForceFieldToggleInstigator);
				if(!TargetableComp.IsDisabledForPlayer(MatchingPlayer.OtherPlayer))
					TargetableComp.DisableForPlayer(MatchingPlayer.OtherPlayer, ForceFieldToggleInstigator);
			}
		}
		if (Type == EIslandForceFieldType::Red)
		{
			AHazePlayerCharacter MatchingPlayer = IslandRedBlueWeapon::GetPlayerForColor(EIslandRedBlueWeaponType::Red);			
			ResponseComp.BlockImpactForPlayer(MatchingPlayer.OtherPlayer, Instigator);
			if (TargetableComp != nullptr)
			{
				if(TargetableComp.IsDisabledForPlayer(MatchingPlayer))
					TargetableComp.EnableForPlayer(MatchingPlayer, ForceFieldToggleInstigator);
				if(!TargetableComp.IsDisabledForPlayer(MatchingPlayer.OtherPlayer))
					TargetableComp.DisableForPlayer(MatchingPlayer.OtherPlayer, ForceFieldToggleInstigator);
			}
		}
	}


	FLinearColor GetForceFieldColor(EIslandForceFieldType Type)
	{
		if(Type == EIslandForceFieldType::Blue)
			return FLinearColor(0.00, 5, 13.00);

		if (Type == EIslandForceFieldType::Red)
			return FLinearColor(15.0, 0.0, 0.0);
		
		if (Type == EIslandForceFieldType::Both)
			return FLinearColor(2, 0.00, 3.0);
		
		devError("Missing force field type if statement!");
		return FLinearColor();
	}

	FLinearColor GetForceFieldFillColor(EIslandForceFieldType Type)
	{
		if(Type == EIslandForceFieldType::Blue)
			return FLinearColor(5.0, 0.0, 0.0);

		if(Type == EIslandForceFieldType::Red)
			return FLinearColor(5.0, 0.0, 0.0);

		if(Type == EIslandForceFieldType::Both)
			return FLinearColor(5.0, 0.0, 0.0);

		devError("Missing force field type if statement!");
		return FLinearColor();
	}

	EIslandForceFieldEffectType GetEffectType(AActor Owner, EIslandForceFieldType Type)
	{
		auto EffectType = EIslandForceFieldEffectType::MAX;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
		{
			EIslandRedBlueWeaponType Color =  IslandRedBlueWeapon::GetPlayerColor(Player);
			if (Color == EIslandRedBlueWeaponType::Red)
				EffectType = EIslandForceFieldEffectType::PlayerRed;
			EffectType = EIslandForceFieldEffectType::PlayerBlue;
		}
		else
		{
			switch(Type)
			{
				case EIslandForceFieldType::Blue:
					EffectType = EIslandForceFieldEffectType::EnemyBlue;
					break;
				case EIslandForceFieldType::Red:
					EffectType = EIslandForceFieldEffectType::EnemyRed;
					break;
				case EIslandForceFieldType::Both:
					EffectType = EIslandForceFieldEffectType::EnemyBoth;
					break;
				default:
					check(false, "Undefined ForceFieldType");
					break;
			}
		}
		return EffectType;
	}

	EIslandForceFieldType GetPlayerForceFieldType(AHazePlayerCharacter Player)
	{
		devCheck(Player != nullptr, "Called function with nullptr argument.");
		if (Player == Game::Mio)
			return EIslandForceFieldType::Red; // Mio
		else
			return EIslandForceFieldType::Blue; // Zoe
	}



	// Let projectiles through force field obstacles.
	// Called in both projectile actor when it travels and in projectile component to determine blocking hit impact
	bool HasHitForceFieldObstacleHole(FHitResult Hit)
	{
		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		if(ForceField == nullptr)
			return false;

		if(ForceField.IsPointInsideHoles(Hit.ImpactPoint))
			return true;

		return false;
	}
}