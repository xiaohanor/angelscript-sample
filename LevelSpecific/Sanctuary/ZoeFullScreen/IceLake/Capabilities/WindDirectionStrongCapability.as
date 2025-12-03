class UWindDirectionStrongCapability : UHazePlayerCapability
{
	UWindDirectionComponent PlayerComp;
	UWindDirectionDataComponent DataComp;

	private FHazeAcceleratedVector AccWindDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UWindDirectionComponent::Get(Player);
		DataComp = UWindDirectionDataComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
        if(!PlayerComp.bIsStrongWind)
            return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if(!PlayerComp.bIsStrongWind)
            return true;

		return false;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		FVector ZoeVelocity = Game::GetZoe().ActorVelocity;
		PlayerComp.SetWindDirection(-ZoeVelocity, PlayerComp.WindLocation);

        if(PlayerComp.WindNiagara == nullptr)
		{
			PlayerComp.WindNiagara = Niagara::SpawnLoopingNiagaraSystemAttached(DataComp.WindNiagara_Sys, Game::GetZoe().RootComponent);
			PlayerComp.WindNiagara.SetRelativeLocation(FVector(0, 0, 1000));
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        FVector2D InputVector = MioFullScreen::GetStickInput(this);

		// Filip TODO: Rotate with camera

        if(InputVector.SizeSquared() < KINDA_SMALL_NUMBER)
            InputVector = FVector2D(PlayerComp.WindDirection.X, PlayerComp.WindDirection.Y);

        InputVector.Normalize();

        const FVector WindForce = FVector(InputVector.Y, InputVector.X, 0.0);
        AccWindDirection.AccelerateTo(WindForce, DataComp.Settings.WindDirectionAccelerationDuration, DeltaTime);

        PlayerComp.SetWindDirection(WindForce, PlayerComp.WindLocation);

        float WindParticleIntensity = 100 * DataComp.Settings.WindStrongStrength;
        FVector Gravity = FVector(0, 0, -980);
        FVector WindVelocity = Gravity + (WindForce * WindParticleIntensity);
        PlayerComp.WindNiagara.SetVectorParameter(n"WindVelocity", WindVelocity);
	}
}