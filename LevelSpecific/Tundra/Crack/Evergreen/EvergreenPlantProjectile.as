class AEvergreenPlantProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!HasControl())
			return;

		auto Crawler = Cast<AEvergreenPoleCrawler>(OtherActor);
		if(Crawler != nullptr)
			CrumbTriggerHitCrawler(Crawler);

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
			CrumbTriggerHitPlayer(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerHitCrawler(AEvergreenPoleCrawler Crawler)
	{
		Crawler.DestroyCrawler();
		DestroyProjectile();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerHitPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
		DestroyProjectile();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector(1200 * DeltaSeconds, 0, 0));
	}

	UFUNCTION(BlueprintCallable)
	void DestroyProjectile()
	{
		AddActorDisable(this);
	}
};