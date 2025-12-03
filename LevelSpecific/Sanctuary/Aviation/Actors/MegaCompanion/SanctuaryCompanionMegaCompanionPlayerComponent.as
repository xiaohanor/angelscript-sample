namespace MegaCompanion
{
	UFUNCTION(BlueprintPure, DisplayName = "Get MegaCompanion", Category = "Sanctuary|Hydra")
	ASanctuaryMegaCompanion BP_GetMegaCompanion(AHazePlayerCharacter Player)
	{
		USanctuaryCompanionMegaCompanionPlayerComponent Comp = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
		return Comp.MegaCompanion;
	}
}

class USanctuaryCompanionMegaCompanionPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASanctuaryMegaCompanion> MegaLightBirdClass;
	UPROPERTY()
	TSubclassOf<ASanctuaryMegaCompanion> MegaDarkMorayClass;

	UPROPERTY()
	TSubclassOf<ASanctuaryMegaCompanionAttackDisc> AttackVFXDiscClass;

	ASanctuaryMegaCompanion MegaCompanion;
	bool bIsRiding = false;
	bool bModifiedMioAttachedTransform = false;
	ASanctuaryMegaCompanionAttackDisc AttackDisc;

	UHazeCrumbSyncedVectorComponent SyncedDiscLocation;
	UHazeCrumbSyncedVectorComponent SyncedDiscUpvector;
	UHazeCrumbSyncedFloatComponent SyncedDiscRadius;

	FVector CompanionRidingOffset;
	FHazeAcceleratedVector AccCompanionRidingOffset;

	bool bTutorialStayForDoor = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedDiscLocation = UHazeCrumbSyncedVectorComponent::Create(Owner, n"AttackVFXDisc_Location");
		SyncedDiscUpvector = UHazeCrumbSyncedVectorComponent::Create(Owner, n"AttackVFXDisc_Upvector");
		SyncedDiscRadius = UHazeCrumbSyncedFloatComponent::Create(Owner, n"AttackVFXDisc_Radius");

		if (AttackVFXDiscClass != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
			FString DiscAttackName = "AttackVFXDisc_";
			if (Player.IsMio())
				DiscAttackName += "LightBird";
			else
				DiscAttackName += "DarkMoray";
			AttackDisc = SpawnActor(AttackVFXDiscClass, FVector::ZeroVector, FRotator::ZeroRotator, FName(DiscAttackName));
			AttackDisc.SetIsLight(Player == Game::Mio);
		}
	}
};