struct FDentistBossAttachData
{
	UPROPERTY()
	EDentistBossTool ToolToAttach; 
	UPROPERTY()
	EDentistBossArm ArmToAttachTo = EDentistBossArm::LeftTop;
	UPROPERTY()
	EAttachmentRule AttachRule = EAttachmentRule::SnapToTarget;
}

class UAnimNotify_Dentist_BossToolAttach : UAnimNotifyState
{
	UPROPERTY(EditAnywhere)
	TArray<FDentistBossAttachData> AttachData;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DentistBossToolAttach";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		AttachTool(Dentist);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		AttachTool(Dentist);
		return true;
	}

	void AttachTool(ADentistBoss Dentist) const
	{	
		for(auto Data : AttachData)
		{
			FName AttachmentBoneName;
			switch(Data.ArmToAttachTo)
			{
				case EDentistBossArm::LeftTop :
				{
					AttachmentBoneName = Dentist.LeftUpperAttach;
					break;
				}
				case EDentistBossArm::RightTop :
				{
					AttachmentBoneName = Dentist.RightUpperAttach;
					break;
				}
				case EDentistBossArm::LeftMiddle :
				{
					AttachmentBoneName = Dentist.LeftLowerAttach;
					break;
				}
				case EDentistBossArm::RightMiddle :
				{
					AttachmentBoneName = Dentist.RightLowerAttach;
					break;
				}
				default: break;
			}
			Dentist.Tools[Data.ToolToAttach].AttachToComponent(Dentist.SkelMesh, AttachmentBoneName, Data.AttachRule);
		}
	}
}

struct FDentistBossDetachData
{
	UPROPERTY()
	EDentistBossTool ToolToDetach;
	UPROPERTY()
	EDetachmentRule DetachRule = EDetachmentRule::KeepWorld;
}

class UAnimNotify_Dentist_BossToolDetach : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	TArray<FDentistBossDetachData> DetachData;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DentistBossToolDetach";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		DetachTool(Dentist);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		DetachTool(Dentist);
		return true;
	}

	void DetachTool(ADentistBoss Dentist) const
	{	
		for(auto Data : DetachData)
		{
			Dentist.Tools[Data.ToolToDetach].DetachFromActor(Data.DetachRule);
		}
	}
}

struct FDentistBossAttachDuringData
{
	UPROPERTY()
	EDentistBossTool Tool;
	UPROPERTY()
	EDentistBossArm ArmToAttachTo = EDentistBossArm::LeftTop;
	UPROPERTY()
	EAttachmentRule AttachRule = EAttachmentRule::SnapToTarget;
	UPROPERTY()
	EDetachmentRule DetachRule = EDetachmentRule::KeepWorld;
}

class UAnimNotify_Dentist_BossToolAttachDuring : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	TArray<FDentistBossAttachDuringData> AttachmentData;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DentistBossToolAttachDuring";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		AttachTool(Dentist);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dentist = Cast<ADentistBoss>(MeshComp.Owner);
		if(Dentist == nullptr)
			return true;
		
		DetachTool(Dentist);
		return true;
	}

	void AttachTool(ADentistBoss Dentist) const
	{	
		for(auto Data : AttachmentData)
		{
			FName AttachmentBoneName;
			switch(Data.ArmToAttachTo)
			{
				case EDentistBossArm::LeftTop :
				{
					AttachmentBoneName = Dentist.LeftUpperAttach;
					break;
				}
				case EDentistBossArm::RightTop :
				{
					AttachmentBoneName = Dentist.RightUpperAttach;
					break;
				}
				case EDentistBossArm::LeftMiddle :
				{
					AttachmentBoneName = Dentist.LeftLowerAttach;
					break;
				}
				case EDentistBossArm::RightMiddle :
				{
					AttachmentBoneName = Dentist.RightLowerAttach;
					break;
				}
				default: break;
			}
			Dentist.Tools[Data.Tool].AttachToComponent(Dentist.SkelMesh, AttachmentBoneName, Data.AttachRule);
		}
	}

	void DetachTool(ADentistBoss Dentist) const
	{
		for(auto Data : AttachmentData)
		{
			Dentist.Tools[Data.Tool].DetachFromActor(Data.DetachRule);
		}
	}
}