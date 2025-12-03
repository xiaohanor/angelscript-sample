class ASummitRaftWaterStaticMeshActor : AStaticMeshActor
{
	default StaticMeshComponent.SetCollisionProfileName(n"BlockAllDynamic");
	default StaticMeshComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default StaticMeshComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	//default StaticMeshComponent.SetCollisionResponseToChannel(SummitRaft::RaftCollisionChannel, ECollisionResponse::ECR_Block);
	default StaticMeshComponent.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	default StaticMeshComponent.ComponentTags.Add(ComponentTags::RaftTraversable);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StaticMeshComponent.SetCollisionProfileName(n"BlockAllDynamic");
		StaticMeshComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		StaticMeshComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
		//StaticMeshComponent.SetCollisionResponseToChannel(SummitRaft::RaftCollisionChannel, ECollisionResponse::ECR_Block);
		StaticMeshComponent.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}
}