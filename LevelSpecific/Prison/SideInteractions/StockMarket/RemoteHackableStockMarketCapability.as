class URemoteHackableStockMarketCapability : URemoteHackableBaseCapability
{
	ARemoteHackableStockMarket StockMarket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		StockMarket = Cast<ARemoteHackableStockMarket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		StockMarket.InputValue += GetAttributeFloat(AttributeNames::MoveForward) * DeltaTime;
	}
}