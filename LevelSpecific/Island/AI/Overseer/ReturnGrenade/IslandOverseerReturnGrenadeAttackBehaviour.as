struct FIslandOverseerReturnGrenadeAttackBehaviourParams
{
	TArray<FIslandOverseerReturnGrenadeAttackLocation> RandomTargetLocations;
}

struct FIslandOverseerReturnGrenadeAttackLocation
{
	int Index;
	FVector Location;
}

class UIslandOverseerReturnGrenadeAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Attack");

	UIslandOverseerReturnGrenadeLauncherComponent Launcher;
	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerSettings Settings;
	AHazeCharacter Character;

	AIslandOverseerReturnGrenadeTargetVolume TargetVolume;
	TArray<FVector> TargetVolumeCells;
	const int TargetVolumeRowCount = 2;
	const int TargetVolumeCellCount = 5;
	const float CellPadding = 50;
	int CellTotalCount;

	float RecoverDuration = 1;
	float FiredTime = 0.0;
	int FiredProjectiles = 0;
	int AdditionalGrenades = 0;
	bool bBlue;
	bool bFired;
	TArray<AIslandOverseerReturnGrenade> RemoveGrenades;
	TArray<AIslandOverseerReturnGrenade> Grenades;
	TArray<UIslandOverseerReturnGrenadeCrosshairWidget> CrosshairWidgets;
	TArray<FIslandOverseerReturnGrenadeAttackLocation> TargetLocations;

	TArray<FIslandOverseerReturnGrenadeAttackLocation> RandomTargetLocations;
	int RandomTargetLocationsIndex;

	TArray<FVector2D> ReturnScreenLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		Launcher = UIslandOverseerReturnGrenadeLauncherComponent::Get(Owner);
		TargetVolume = TListedActors<AIslandOverseerReturnGrenadeTargetVolume>()[0];
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");

		Launcher.PrepareProjectiles(Settings.ReturnGrenadeProjectileAmountMax + Settings.ReturnGrenadeProjectileAmount + Settings.ReturnGrenadeProjectileMaxAdditionalAmount);

		ReturnScreenLocations.Add(FVector2D(0.2, 0.3));
		ReturnScreenLocations.Add(FVector2D(0.2, 0.7));
		ReturnScreenLocations.Add(FVector2D(0.8, 0.3));
		ReturnScreenLocations.Add(FVector2D(0.8, 0.7));

		CellTotalCount = TargetVolumeRowCount * TargetVolumeCellCount;
		SetupCells();
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(OldPhase != EIslandOverseerPhase::PovCombat)
			return;

		if(IsActive())
			DeactivateBehaviour();
		for(AIslandOverseerReturnGrenade Grenade : Grenades)
			Grenade.Explode();
		Grenades.Empty();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerReturnGrenadeAttackBehaviourParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(Grenades.Num() >= Settings.ReturnGrenadeProjectileAmountMax)
			return false;
		
		for(int i = 0; i < CellTotalCount; i++)
			Params.RandomTargetLocations.Add(GetRandomLocation(i));
		Params.RandomTargetLocations.Shuffle();

		return true;
	}

	private FIslandOverseerReturnGrenadeAttackLocation GetRandomLocation(int Index) const
	{
		FIslandOverseerReturnGrenadeAttackLocation Location;
		Location.Location = GetCellLocation(Index);
		Location.Index = Index;
		return Location;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverseerReturnGrenadeAttackBehaviourParams Params)
	{
		Super::OnActivated();

		RandomTargetLocations = Params.RandomTargetLocations;
		FiredProjectiles = 0;
		TargetLocations.Empty();

		for(auto Grenade : RemoveGrenades)
		{
			if(Grenades.Contains(Grenade))
				Grenades.Remove(Grenade);
		}
		RemoveGrenades.Empty();

		SetTargetLocations();

		for(FIslandOverseerReturnGrenadeAttackLocation Location : TargetLocations)
		{
			auto Widget = SceneView::FullScreenPlayer.AddWidget(Launcher.CrosshairWidgetClass, EHazeWidgetLayer::Overlay);
			Widget.TargetLocation = Location.Location;
			Widget.AccLocation.SnapTo(Widget.TargetLocation + Owner.ActorRightVector.RotateAngleAxis(Math::RandRange(0, 360), Owner.ActorUpVector) * 500);
			Widget.OnTelegraphing();
			CrosshairWidgets.Add(Widget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		for(UIslandOverseerReturnGrenadeCrosshairWidget Widget : CrosshairWidgets)
			SceneView::FullScreenPlayer.RemoveWidget(Widget);
		CrosshairWidgets.Empty();
		Cooldown.Set(Settings.ReturnGrenadeCooldown);

		if(AdditionalGrenades < Settings.ReturnGrenadeProjectileMaxAdditionalAmount)
			AdditionalGrenades++;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(UIslandOverseerReturnGrenadeCrosshairWidget Widget : CrosshairWidgets)
		{
			Widget.AccLocation.AccelerateTo(Widget.TargetLocation, Settings.ReturnGrenadeTelegraphDuration, DeltaTime);
			Widget.SetWidgetWorldPosition(Widget.AccLocation.Value);
		}

		if(ActiveDuration < Settings.ReturnGrenadeTelegraphDuration)
			return;

		if(FiredProjectiles >= TargetLocations.Num())
		{
			if(Time::GetGameTimeSince(FiredTime) > RecoverDuration)
				DeactivateBehaviour();
		}
		else if(CanFire())
		{
			FVector TargetLocation = TargetLocations[FiredProjectiles].Location;
			FVector FireDir = (TargetLocation - Launcher.LaunchLocation).GetSafeNormal();
			CrosshairWidgets[FiredProjectiles].OnFire();
			if(HasControl())
				CrumbFireProjectile(FireDir, TargetLocation, TargetLocations[FiredProjectiles].Index, MakeBlue(), Math::RandRange(0, ReturnScreenLocations.Num()-1));
		}
	}

	private bool CanFire()
	{
		if(FiredTime == 0)
			return true;
		if(Time::GetGameTimeSince(FiredTime) > Settings.ReturnGrenadeLaunchInterval)
			return true;
		return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFireProjectile(FVector AimDir, FVector TargetLocation, int LocationIndex, bool bMakeBlue, int ScreenIndex)
	{
		UBasicAIProjectileComponent Projectile = Launcher.Launch(AimDir * Settings.ReturnGrenadeLaunchSpeed);
		Projectile.Damage = Settings.ReturnGrenadeBossDamage;
		AIslandOverseerReturnGrenade Grenade = Cast<AIslandOverseerReturnGrenade>(Projectile.Owner);
		Grenade.SetColor(bMakeBlue);
		Grenade.TargetLocation = TargetLocation;
		Grenade.LocationIndex = LocationIndex;
		Grenade.Launcher = Owner;
		Grenade.ReturnScreenLocation = ReturnScreenLocations[ScreenIndex];
		Grenades.Add(Grenade);
		Grenade.RespawnComp.OnUnspawn.AddUFunction(this, n"UnspawnedGrenade");
		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
	}

	private bool MakeBlue()
	{
		int BlueCount = 0;
		int RedCount = 0;
		for(AIslandOverseerReturnGrenade Grenade : Grenades)
		{
			if(Grenade.bBlue)
				BlueCount++;
			else
				RedCount++;
		}
		return RedCount > BlueCount;
	}

	private void SetTargetLocations()
	{
		TArray<int> UsedIndexes;
		for(int i = 0; i < Settings.ReturnGrenadeProjectileAmount + AdditionalGrenades; i++)
		{
			for(int LocationIndex = 0; LocationIndex < CellTotalCount; LocationIndex++)
			{
				bool bUsed = false;
				for(AIslandOverseerReturnGrenade Grenade : Grenades)
				{
					if(Grenade.LocationIndex != RandomTargetLocations[LocationIndex].Index)
						continue;
					bUsed = true;
					break;	
				}
				if(bUsed)
					continue;
				if(UsedIndexes.Contains(LocationIndex))
					continue;

				TargetLocations.Add(RandomTargetLocations[LocationIndex]);
				UsedIndexes.Add(LocationIndex);
				break;
			}
		}
	}

	private FVector GetCellLocation(int Index) const
	{
		FVector Cell = TargetVolumeCells[Index];
		float LocationX = Cell.X + Math::RandRange(CellPadding, GetCellSize() - CellPadding);
		float LocationY = Cell.Y + Math::RandRange(CellPadding, GetRowSize() - CellPadding);
		return FVector(LocationX, LocationY, Cell.Z);
	}

	private void SetupCells()
	{
		for(int RowIndex = 0; RowIndex < TargetVolumeRowCount; RowIndex++)
		{
			for(int CellIndex = 0; CellIndex < TargetVolumeCellCount; CellIndex++)
			{
				float LocationX = TargetVolume.ActorLocation.X - TargetVolume.Bounds.BoxExtent.X + GetCellSize() * CellIndex;
				float LocationY = TargetVolume.ActorLocation.Y - TargetVolume.Bounds.BoxExtent.Y + GetRowSize() * RowIndex;
				float LocationZ = TargetVolume.ActorLocation.Z - TargetVolume.Bounds.BoxExtent.Z;
				TargetVolumeCells.Add(FVector(LocationX, LocationY, LocationZ));
			}
		}
	}

	private float GetCellSize() const
	{
		return ((TargetVolume.Bounds.BoxExtent.X * 2) / TargetVolumeCellCount);
	}

	private float GetRowSize() const
	{
		return ((TargetVolume.Bounds.BoxExtent.Y * 2) / TargetVolumeRowCount);
	}

	UFUNCTION()
	private void UnspawnedGrenade(AHazeActor RespawnableActor)
	{
		AIslandOverseerReturnGrenade Grenade = Cast<AIslandOverseerReturnGrenade>(RespawnableActor);
		if(Grenade != nullptr)
			RemoveGrenades.Add(Grenade);
	}
}