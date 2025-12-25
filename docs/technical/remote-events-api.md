# 📡 RemoteEvents API Reference

Dokumentasi lengkap semua RemoteEvents dan RemoteFunctions di proyek.

---

## 🔫 Combat Events

### ShootEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `tool: Tool`, `cameraDirection: Vector3`, `isAiming: boolean` |
| **Handler** | `WeaponManager.lua:214` |
| **Description** | Request tembakan ke server untuk validasi & damage calculation |

### ReloadEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `tool: Tool` |
| **Handler** | `WeaponManager.lua:586` |
| **Description** | Request reload senjata |

### AmmoUpdateEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `weaponName: string`, `currentAmmo: number`, `reserveAmmo: number`, `animated: boolean`, `isReloading?: boolean` |
| **Handler** | `WeaponClient.lua` |
| **Description** | Sync ammo count ke client |

### HitmarkerEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `isHeadshot: boolean` |
| **Handler** | `HitmarkerUI.lua` |
| **Description** | Trigger hitmarker visual (white = body, red = headshot) |

### TracerEvent / TracerBroadcast
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server → All Clients |
| **Parameters** | `startPos: Vector3`, `endPos: Vector3`, `weaponName: string` |
| **Handler** | `TracerHandler.lua`, `TracerClient.lua` |
| **Description** | Replicate tracer VFX ke semua pemain |

### MuzzleFlashEvent / MuzzleFlashBroadcast
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server → All Clients |
| **Parameters** | `handle: BasePart`, `weaponName: string` |
| **Handler** | `MuzzleFlashHandler.lua`, `MuzzleFlashClient.lua` |
| **Description** | Replicate muzzle flash VFX |

### BulletholeEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `position: Vector3`, `normal: Vector3` |
| **Handler** | `BulletholeClient.lua` |
| **Description** | Spawn bullethole decal pada hit surface |

---

## 💀 Knock & Revive Events

### KnockEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `isKnocked: boolean` |
| **Handler** | `WeaponClient.lua`, `StatusHUD.lua`, `MobileControlsClient.lua` |
| **Description** | Toggle knocked state UI & controls |

### ReviveEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `target: Player` |
| **Handler** | `KnockManager.lua:159` |
| **Description** | Start revive pada target player |

### CancelReviveEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | (none) |
| **Handler** | `KnockManager.lua:155` |
| **Description** | Cancel revive yang sedang berjalan |

### ReviveProgressEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `progress: number`, `cancelled: boolean`, `totalTime: number` |
| **Handler** | `ReviveUI.lua` |
| **Description** | Update revive progress bar |

### PingKnockedPlayerEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server → All Clients |
| **Parameters** | (none) |
| **Handler** | `KnockManager.lua:313`, `PingKnockDisplay.lua` |
| **Description** | Broadcast ping dari knocked player |

---

## 🌊 Wave & Game Events

### WaveUpdateEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `waveNumber: number`, `zombiesRemaining: number` |
| **Handler** | `WaveCounterUI.lua` |
| **Description** | Update wave counter UI |

### WaveCountdownEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `seconds: number` |
| **Handler** | `WaveCounterUI.lua` |
| **Description** | Countdown sebelum wave dimulai |

### ObjectiveUpdateEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `objective: string` |
| **Handler** | `WaveCounterUI.lua` |
| **Description** | Update objective text |

### GameOverEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | (wave stats) |
| **Handler** | `GameOverUI.lua` |
| **Description** | Trigger game over screen |

### MissionCompleteEvent
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | (mission rewards) |
| **Handler** | `VictoryUI.lua` |
| **Description** | Trigger victory screen |

### StartGameEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | (none) |
| **Handler** | `GameManager.lua:743` |
| **Description** | Vote untuk start game |

### CancelStartVoteEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | (none) |
| **Handler** | `GameManager.lua:760` |
| **Description** | Cancel vote start |

### ExitGameEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | (none) |
| **Handler** | `GameManager.lua:772` |
| **Description** | Request keluar dari game |

---

## 🏠 Lobby Events

### LobbyRemote (Multi-Action)
| Property | Value |
|:---------|:------|
| **Direction** | Bidirectional |
| **Handler** | `LobbyRoomManager.lua:716` |

**Client → Server Actions:**
| Action | Data |
|:-------|:-----|
| `createRoom` | `{gameMode, difficulty, privacy, maxPlayers}` |
| `joinRoom` | `{roomId}` or `{roomCode}` |
| `leaveRoom` | (none) |
| `forceStartGame` | (none) |
| `startMatchmaking` | `{gameMode, difficulty}` |
| `cancelMatchmaking` | (none) |
| `getPublicRooms` | (none) |
| `startSoloGame` | `{gameMode, difficulty}` |

**Server → Client Responses:**
| Action | Data |
|:-------|:-----|
| `roomCreated` | `{roomId, roomCode}` |
| `joinSuccess` | `{roomId}` |
| `joinFailed` | `{reason}` |
| `roomUpdate` | `{players, settings}` |
| `countdownUpdate` | `{value}` |
| `publicRoomsUpdate` | `[rooms]` |

---

## 💰 Economy Events

### GachaRollEvent
| Property | Value |
|:---------|:------|
| **Direction** | Bidirectional |
| **Parameters** | (request) / (result with weapon data) |
| **Handler** | `GachaManager.lua:53` |
| **Description** | Single gacha roll |

### GachaMultiRollEvent
| Property | Value |
|:---------|:------|
| **Direction** | Bidirectional |
| **Parameters** | (request) / (results array) |
| **Handler** | `GachaManager.lua:79` |
| **Description** | Multi-roll gacha (10x) |

### ConfirmUpgrade
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `tool: Tool`, `confirm: boolean` |
| **Handler** | `UpgradeManager.lua:107` |
| **Description** | Confirm weapon upgrade |

### UpgradeUIOpen
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `weaponData: table` |
| **Handler** | `UpgradeShopUI.lua` |
| **Description** | Open upgrade shop dengan data senjata |

---

## ⚡ Tactical Boost Events

> **Note:** Internal code uses "Element" naming for backwards compatibility.

### ActivateElementEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `elementName: string` |
| **Handler** | `ElementConfigModule.lua:562` |
| **Description** | Activate purchased tactical boost |

### ElementActivated
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `elementName: string`, `duration: number` |
| **Handler** | Client UI |
| **Description** | Notify tactical boost activation |

### ElementDeactivated
| Property | Value |
|:---------|:------|
| **Direction** | Server → Client |
| **Parameters** | `elementName: string` |
| **Handler** | Client UI |
| **Description** | Notify tactical boost expiration |

---

## 🎯 Movement Events

### UpdateWalkSpeedModifierEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `modifierName: string`, `value: number or boolean` |
| **Handler** | `WalkSpeedManager.lua:121` |
| **Description** | Modify walk speed (aim/reload/sprint) |

### SprintEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `action: "Start" or "Stop"` |
| **Handler** | `SprintManager.lua:101` |
| **Description** | Toggle sprint state |

### JumpEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | (none) |
| **Handler** | `SprintManager.lua:130` |
| **Description** | Handle jump (stamina cost) |

### LookEvent
| Property | Value |
|:---------|:------|
| **Direction** | Client → Server |
| **Parameters** | `lookVectorY: number` |
| **Handler** | `LookReplicationHandler.server.lua:47` |
| **Description** | Replicate head look direction |

---

## 📞 RemoteFunctions

### PurchaseRandomWeapon
| Property | Value |
|:---------|:------|
| **Parameters** | (none) |
| **Returns** | `{success: boolean, weaponName?: string, error?: string}` |
| **Handler** | `RandomWeaponManager.lua` |

### GetRandomWeaponCost
| Property | Value |
|:---------|:------|
| **Parameters** | (none) |
| **Returns** | `cost: number` |
| **Handler** | `RandomWeaponManager.lua` |

### UpgradeWeaponRF
| Property | Value |
|:---------|:------|
| **Parameters** | `weaponName: string` |
| **Returns** | `{success: boolean, newLevel?: number}` |
| **Handler** | `UpgradeManager.lua` |

### PurchasePerk
| Property | Value |
|:---------|:------|
| **Parameters** | `perkName: string` |
| **Returns** | `{success: boolean}` |
| **Handler** | `PerkModule.lua` |

### PurchaseTacticalBoost (PurchaseElement)
| Property | Value |
|:---------|:------|
| **Parameters** | `elementName: string` |
| **Returns** | `{success: boolean}` |
| **Handler** | `ElementVendingManager.lua` |

### GetMissionData / ClaimMissionReward / RerollMission
| Property | Value |
|:---------|:------|
| **Handler** | `MissionManager.lua` |
| **Description** | Mission system functions |

### GetDailyRewardInfo / ClaimDailyReward
| Property | Value |
|:---------|:------|
| **Handler** | `LobbyManager.lua` |
| **Description** | Daily reward system |

### GetInventoryData
| Property | Value |
|:---------|:------|
| **Parameters** | (none) |
| **Returns** | `{weapons: table, skins: table}` |
| **Handler** | `InventoryManager.lua` |

---

*Generated: 2025-12-25*
