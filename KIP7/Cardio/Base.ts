class LockInfo {
    type: AccountType; // 타입
    amount: number; // 락업 수량
    distributedTime: number; // 분배된 시간 
    lockUpPeriodMonth: number; // 초기 락업 기간 (달)
    lastUnlockTimestamp: number; // 마지막 언락 시간 (mill)
    unlockAmountPerCount: number; // 언락 시키는 퍼센트
    unlockCount: number; // 남은 언락 
}

enum AccountType {
    A = "A",
    B = "B",
    C = "C",
    D = "D",
    E = "E",
}

class CardioCoin {
    private name = "CardioCoin";
    private symbol = "CRDC";
    private decimals = 18;
    private totalSupply = 12000000000;

    private ICO_TIME = 0;

    // cardio에서 관리하는 지갑 주소 { '123123': 'A', '1231231': 'B', ...}
    private adminAccountTypes: { [address: string]: AccountType } = {};
    private balances: { [address: string]: number } = {};
    private lockers: { [address: string]: LockInfo } = {};

    constructor() {
			// set owner
		}

    public transfer(from: string, to: string, amount: number) {
        // 타입 계정으로 부터 온 전송인가
        let adminAccountType = this.adminAccountTypes[from];
        if (adminAccountType) {
            this.addLocker(from, adminAccountType, amount);
        }

        // 락업된 유저인가?
        let locker = this.lockers[to];
        if (locker) {
            // 락업된 유저면 락업해제 시도
            this.unLock(to);
        }

        // transfer
        // require(amount <= this.balances[from]);
        // require(to != address(0));
        this.balances[from] = this.balances[from] - amount;
        this.balances[to] = this.balances[to] + amount;
    }

    private addLocker(address: string, type: AccountType, amount: number) {
        this.lockers[address] = this.getLockInfo(type, amount);
    }

    private getLockInfo(type: AccountType, amount: number): LockInfo {
        if (type === "A") {
            // 분배 이후 상장과 동시에 20% 락업 해제, 2달 이후 부터 매달 20%씩 4개월간 락업 해제
            // TODO: 상장과 동시에 20%락업 해제 반영안됨 ICO_TIME?
            return {
                type: type,
                amount: amount,
                distributedTime: Date.now(),
                lockUpPeriodMonth: 2,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: amount * (20 / 100),
                unlockCount: 5
            }
        } else if (type === "B") {
            // 토큰 생성하자마자 진행하면 될듯? B는 따로 
            // 토큰 생성일로부터 매달 1%씩 락업 해제 (100달)
            return {
                type: type,
                amount: amount,
                distributedTime: Date.now(),
                lockUpPeriodMonth: 0,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: amount * (1 / 100),
                unlockCount: 100
            }
        } else if (type === "C") {
            // 분배 이후 3개월간 락업, 3개월 이후 10%씩 10개월간 락업 해제
            return {
                type: type,
                amount: amount,
                distributedTime: Date.now(),
                lockUpPeriodMonth: 3,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: amount * (10 / 100),
                unlockCount: 10
            }
        } else if (type === "D") {
            // 분배 이후 12개월간 락업, 12개월 이후 10%씩 10개월간 락업 해제
            return {
                type: type,
                amount: amount,
                distributedTime: Date.now(),
                lockUpPeriodMonth: 12,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: amount * (10 / 100),
                unlockCount: 10
            }
        } else if (type === "E") {
            // 토큰 생성하자마자 진행하면 될듯? E는 따로 
            // 토큰 생성일로부터 매달 5%씩 락업 해제 (20달)
            return {
                type: type,
                amount: amount,
                distributedTime: Date.now(),
                lockUpPeriodMonth: 0,
                lastUnlockTimestamp: 0,
                unlockAmountPerCount: amount * (5 / 100),
                unlockCount: 20
            }
        } else {
            throw Error
        }
    }

    private unLock(address: string) {
        let lockInfo = this.lockers[address];
        if (!lockInfo) {
            return;
        }

        if (this.isOverLockUpPeriodMonth(lockInfo.distributedTime, lockInfo.lockUpPeriodMonth) === false) {
            return;
        }

        let now = Date.now();
        let count = this.getCount(now, lockInfo);
        let unlockAmount = count * lockInfo.unlockAmountPerCount;
        let unlockCount = lockInfo.unlockCount - count; // 새로 추가
				if (lockInfo.amount - unlockAmount < 0 || unlockCount <= 0) {
            unlockAmount = lockInfo.amount;
        }

        // lockInfo 정보 갱신
        lockInfo.lastUnlockTimestamp = now;
        lockInfo.unlockCount = unlockCount;
        lockInfo.amount = lockInfo.amount - unlockAmount;
        // unlock 된 수량 더하기
        this.balances[address] = this.balances[address] + unlockAmount;
    }

    private getCount(now: number, lockInfo: LockInfo) {
        const startTime = lockInfo.distributedTime + lockInfo.lockUpPeriodMonth * 30 * 24 * 60 * 60 * 1000;

        let count = 0;
        if (lockInfo.lastUnlockTimestamp === 0) {
            count = parseInt(this.convertMSToMonth(now - startTime)+'');
        } else {
            // let count = (now - startTime) / 1000 / 60 / 60 / 24;
            // let count2 = (lockInfo.lastUnlockTimestamp - startTime) / 1000 / 60 / 60 / 24 / 30;
            // lockInfo.unlockCount = lockInfo.unlockCount - (count - count2);
            // count = this.convertMSToMonth(now - lockInfo.lastUnlockTimestamp);
						let count = this.convertMSToMonth((now - startTime));
            let count2 = this.convertMSToMonth(lockInfo.lastUnlockTimestamp - startTime);
            count = parseInt(count + '') - parseInt(count2 + '');
        }

        return count;
    }

    private convertMSToMonth(value: number) {
        return value / 1000 / 60 / 60 / 24 / 30;
    }

    private isOverLockUpPeriodMonth(time: number, period: number) {
        return this.convertMSToMonth((Date.now() - time)) > period
    }

    public addAdminAccountType(address: string, type: AccountType) {
        this.adminAccountTypes[address] = type;
    }

    public balanceOf(address: string) {
        return this.balances[address] + this.lockers[address].amount;
    }

    public balanceInfo(address: string) {
        return this.balances[address];
    }

    public lockUpInfo(address: string) {
        return this.lockers[address];
    }

    public updateICOTime(time: number) {
        return this.ICO_TIME = time;
    }

		private burn(address: string) {
        // ?
    }
}