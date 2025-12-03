const FConsoleVariable CVar_DisplayPlayerNames("Haze.WhoIsWho", 0);

class UPlayerDebugWhoIsWhoCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterPhysics;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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
	void TickActive(float DeltaTime)
	{
		int DisplayValue = CVar_DisplayPlayerNames.GetInt();
		if (DisplayValue != 0)
		{
			FString PlayerName = Player.IsZoe() ? "Zoe" : "Mio";
			float Size = 2.0;
			if(DisplayValue > 1)
				Size = 10.0;
			
			FVector Location = Player.GetActorLocation();
			FVector2D Offset = FVector2D(0.0, 20.0);

			if(DisplayValue < 0)
			{
				Location = Player.Mesh.GetSocketLocation(n"Head");
				Offset = FVector2D(0.0, -30.0);
			}

			Debug::DrawDebugString(Location, PlayerName, Player.GetPlayerDebugColor(), 0, Size, ScreenSpaceOffset = Offset);
		}
	}
};