class APhalanxGem : ASummitNightQueenGem
{
	float Speed = 250.0; 

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) override
	{
		Super::Tick(DeltaSeconds);

		if (!bStartActive)
			return;

		FVector Direction = (Game::Mio.ActorLocation - ActorLocation);
		Direction = Direction.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		ActorLocation += Direction * Speed * DeltaSeconds;
	}
}