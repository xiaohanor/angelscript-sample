enum EMedallionBallistaKillSequence
{
	One,
	Two,
	Three,
}

event void MedallionStartBallistaKillEvent(EMedallionBallistaKillSequence DesiredSequence, ASanctuaryBossMedallionHydra KilledHydra);

class ABallistaHydraActorReferences : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	ABallistaHydraSpline Spline;
	UPROPERTY(EditInstanceOnly)
	ASanctuaryHydraKillerBallista FirstBallista;
	UPROPERTY(EditInstanceOnly)
	ASanctuaryHydraKillerBallista SecondBallista;
	UPROPERTY(EditInstanceOnly)
	ASanctuaryHydraKillerBallista ThirdBallista;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor MioDeathCamera;
	UPROPERTY(EditAnywhere)
	AFocusCameraActor ZoeDeathCamera;
	UPROPERTY(EditAnywhere)
	float DeathCameraBlendInTime = 1.0;
	UPROPERTY(EditAnywhere)
	UPlayerHealthSettings PlayersDuringHydraRegrowHealthSettings;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SequenceKillHydra1;
	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SequenceKillHydra2;
	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SequenceKillHydra3;

	UPROPERTY(EditAnywhere)
	MedallionStartBallistaKillEvent OnStartKillSequence;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UBallistaHydraActorReferencesComponent TempMio = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
		TempMio.Refs = this;
		UBallistaHydraActorReferencesComponent TempZoe = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Zoe);
		TempZoe.Refs = this;
	}
};