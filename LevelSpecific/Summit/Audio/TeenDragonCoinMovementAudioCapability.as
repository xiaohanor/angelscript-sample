class UTeenDragonCoinMovementAudioCapability : UHazePlayerCapability
{
	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> CoinMeshes;

	UDragonFootstepTraceComponent DragonTraceComp;
	UTeenDragonRollComponent RollComp;
	private bool bWasOnCoins = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RollComp = UTeenDragonRollComponent::Get(Player);
		DragonTraceComp = UDragonFootstepTraceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bOnCoins = false;

		if(DragonTraceComp.MoveComp.IsOnAnyGround())
		{
			FHitResult Hit;
			if(RollComp == nullptr || !RollComp.IsRolling())
			{
				auto TraceData = DragonTraceComp.GetTraceData(EDragonFootType::FrontLeft);
				Hit = TraceData.Hit;

			}
			else if(RollComp.IsRolling())
			{	
				Hit = DragonTraceComp.MoveComp.GroundContact.ConvertToHitResult();
			}

			auto HitMeshComponent = Cast<UStaticMeshComponent>(Hit.Component);
			if(HitMeshComponent != nullptr)				
				bOnCoins = CoinMeshes.Contains(HitMeshComponent.StaticMesh);
		}

		if(bOnCoins && !bWasOnCoins)
			DragonTraceComp.OnEnterCoins.Broadcast();			
		else if(!bOnCoins && bWasOnCoins)
			DragonTraceComp.OnExitCoins.Broadcast();
	
		bWasOnCoins = bOnCoins;		
	}
}